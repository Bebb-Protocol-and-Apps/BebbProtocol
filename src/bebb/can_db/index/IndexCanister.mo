import Error "mo:base/Error";
import Text "mo:base/Text";
import Utils "mo:candb/Utils";
import CanisterMap "mo:candb/CanisterMap";
import Buffer "mo:stablebuffer/StableBuffer";

import BebbService "../bebb_service/BebbService";

shared ({caller = owner}) actor class IndexCanister() = this {
  /// @required stable variable (Do not delete or change)
  ///
  /// Holds the CanisterMap of PK -> CanisterIdList
  stable var pkToCanisterMap = CanisterMap.init();

  /// @required API (Do not delete or change)
  ///
  /// Get all canisters for an specific PK
  ///
  /// This method is called often by the candb-client query & update methods. 
  public shared query({caller = caller}) func getCanistersByPK(pk: Text): async [Text] {
    getCanisterIdsIfExists(pk);
  };

  /// @required function (Do not delete or change)
  ///
  /// Helper method acting as an interface for returning an empty array if no canisters
  /// exist for the given PK
  func getCanisterIdsIfExists(pk: Text): [Text] {
    switch(CanisterMap.get(pkToCanisterMap, pk)) {
      case null { [] };
      case (?canisterIdsBuffer) { Buffer.toArray(canisterIdsBuffer) } 
    }
  };

  public shared({caller = caller}) func autoScaleBebbServiceCanister(pk: Text): async Text {
    // Auto-Scaling Authorization - if the request to auto-scale the partition is not coming from an existing canister in the partition, reject it
    if (Utils.callingCanisterOwnsPK(caller, pkToCanisterMap, pk)) {
      Debug.print("creating an additional canister for pk=" # pk);
      await createBebbServiceCanister(pk, ?[owner, Principal.fromActor(this)])
    } else {
      throw Error.reject("not authorized");
    };
  };

  // Partition BebbService canisters by the type (Entity, Bridge, File, User) passed in
  public shared({caller = creator}) func createBebbServiceCanisterByType(serviceType: Text): async ?Text {
    let pk = "type#" # serviceType; // TODO: determine exact pk
    let canisterIds = getCanisterIdsIfExists(pk);
    if (canisterIds == []) {
      ?(await createBebbServiceCanister(pk, ?[owner, Principal.fromActor(this)]));
    // the partition already exists, so don't create a new canister
    } else {
      Debug.print(pk # " already exists");
      null 
    };
  };

  // Spins up a new BebbService canister with the provided pk and controllers
  func createBebbServiceCanister(pk: Text, controllers: ?[Principal]): async Text {
    Debug.print("creating new hello service canister with pk=" # pk);
    // Pre-load 300 billion cycles for the creation of a new Bebb Service canister
    // Note that canister creation costs 100 billion cycles, meaning there are 200 billion
    // left over for the new canister when it is created
    Cycles.add(300_000_000_000); // TODO: enough?
    let newBebbServiceCanister = await BebbService.BebbService({
      partitionKey = pk;
      scalingOptions = {
        autoScalingHook = autoScaleBebbServiceCanister;
        sizeLimit = #heapSize(200_000_000); // Scale out at 200MB TODO: increase (as this seems low)?
        // for auto-scaling testing
        //sizeLimit = #count(3); // Scale out at 3 entities inserted
      };
      owners = controllers;
    });
    let newBebbServiceCanisterPrincipal = Principal.fromActor(newBebbServiceCanister);
    await CA.updateCanisterSettings({
      canisterId = newBebbServiceCanisterPrincipal;
      settings = {
        controllers = controllers;
        compute_allocation = ?0; // TODO: change?
        memory_allocation = ?0; // TODO: change?
        freezing_threshold = ?2592000;
      }
    });

    let newBebbServiceCanisterId = Principal.toText(newBebbServiceCanisterPrincipal);
    // After creating the new Bebb Service canister, add it to the pkToCanisterMap
    pkToCanisterMap := CanisterMap.add(pkToCanisterMap, pk, newBebbServiceCanisterId);

    Debug.print("new Bebb service canisterId=" # newBebbServiceCanisterId);
    newBebbServiceCanisterId;
  };
}