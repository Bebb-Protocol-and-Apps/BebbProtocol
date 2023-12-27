import Error "mo:base/Error";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Utils "mo:candb/Utils";
import CanisterMap "mo:candb/CanisterMap";
import Buffer "mo:stablebuffer/StableBuffer";
import Cycles "mo:base/ExperimentalCycles";
import CA "mo:candb/CanisterActions";
import RangeTreeV2 "mo:candb/RangeTreeV2";
import Admin "mo:candb/CanDBAdmin";

import BebbEntityService "../bebb_service/BebbEntityService";
import BebbBridgeService "../bebb_service/BebbBridgeService";

shared ({caller = owner}) actor class IndexCanister() = this {
  
  /**
   * Stores the can db Entity types that can be used as PK for candb
  */
  public type CanDBEntityTypes = {
    #CanDBTypeEntity;
    #CanDBTypeBridge;
  };

  public shared query func getPkOptions(): async [Text] {
    // var available_pks = [];
    // for (key in CanDBEntityTypes) {
    //   available_pks.append(getCanDbEntityTypePK(key));
    // };
    return ["BebbEntity#", "BebbBridge#"];
  };

  /// @required stable variable (Do not delete or change)
  ///
  /// Holds the CanisterMap of PK -> CanisterIdList
  stable var pkToCanisterMap = CanisterMap.init();

  /// @required API (Do not delete or change)
  ///
  /// Get all canisters for a specific PK
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
    let pk = await getPkForServiceType(serviceType);
    Debug.print("PK used to create the new canister: " # pk);
    let canisterIds = getCanisterIdsIfExists(pk);
    if (canisterIds == []) {
      ?(await createBebbServiceCanister(pk, ?[owner, Principal.fromActor(this)]));
    // the partition already exists, so don't create a new canister
    } else {
      Debug.print(pk # " already exists");
      null 
    };
  };

  /// !! Do not use this method without caller authorization
  /// Upgrade user canisters in a PK range, i.e. rolling upgrades (limit is fixed at upgrading the canisters of 5 PKs per call)
  public shared({ caller = caller }) func upgradeGroupCanistersInPKRange(lowerPK: Text, upperPK: Text, wasmModule: Blob): async Admin.UpgradePKRangeResult {
    // !!! Recommend Adding to prevent anyone from being able to upgrade the wasm of your service actor canisters
    if (caller != owner) { // basic authorization
      return {
        upgradeCanisterResults = [];
        nextKey = null;
      }
    }; 

    // CanDB documentation on this library function - https://www.candb.canscale.dev/CanDBAdmin.html
    await Admin.upgradeCanistersInPKRange({
      canisterMap = pkToCanisterMap;
      lowerPK = lowerPK; 
      upperPK = upperPK;
      limit = 5;
      wasmModule = wasmModule;
      // the scaling options parameter that will be passed to the constructor of the upgraded canister
      scalingOptions = {
        autoScalingHook = autoScaleBebbServiceCanister;
        sizeLimit = #heapSize(200_000_000); // Scale out at 200MB TODO
      };
      // the owners parameter that will be passed to the constructor of the upgraded canister
      owners = ?[owner, Principal.fromActor(this)];
    });
  };

  // Spins up a new Bebb Service canister with the provided pk and controllers
  func createBebbServiceCanister(pk: Text, controllers: ?[Principal]): async Text {
    Debug.print("creating new Bebb service canister with pk=" # pk);
    // Pre-load 300 billion cycles for the creation of a new Bebb Service canister
    // Note that canister creation costs 100 billion cycles, meaning there are 200 billion
    // left over for the new canister when it is created
    Cycles.add(300_000_000_000); // TODO: enough?
    var newBebbServiceCanisterPrincipal = Principal.fromActor(this); // placeholder to be filled
    switch pk {
      case ("BebbEntity#") {
        let newBebbServiceCanister = await BebbEntityService.BebbEntityService({
          partitionKey = pk;
          scalingOptions = {
            autoScalingHook = autoScaleBebbServiceCanister;
            sizeLimit = #heapSize(200_000_000); // Scale out at 200MB TODO: increase (as this seems low)?
            // for auto-scaling testing
            //sizeLimit = #count(3); // Scale out at 3 entities inserted
          };
          owners = controllers;
        });
        newBebbServiceCanisterPrincipal := Principal.fromActor(newBebbServiceCanister);
      };
      case ("BebbBridge#") {
        let newBebbServiceCanister = await BebbBridgeService.BebbBridgeService({
          partitionKey = pk;
          scalingOptions = {
            autoScalingHook = autoScaleBebbServiceCanister;
            sizeLimit = #heapSize(200_000_000); // Scale out at 200MB TODO: increase (as this seems low)?
            // for auto-scaling testing
            //sizeLimit = #count(3); // Scale out at 3 entities inserted
          };
          owners = controllers;
        });
        newBebbServiceCanisterPrincipal := Principal.fromActor(newBebbServiceCanister);
      };
      case (_) { throw Error.reject("Unsupported pk"); };
    };

    assert(newBebbServiceCanisterPrincipal != Principal.fromActor(this)); // Ensure the principal was updated
    
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

  /**
   * Generates the correct PK based on the Entity type
  */
  func getCanDbEntityTypePK(canDBEntityType: CanDBEntityTypes): Text {
    return canDBEntityTypeToString(canDBEntityType) # "#";
  };

  /**
   * Used to convert the different can db entity types to a string to be used
   * for the PK for CanDb
  */
  private func canDBEntityTypeToString(canDBEntityType: CanDBEntityTypes): Text {
    switch canDBEntityType {
      case (#CanDBTypeEntity) "BebbEntity";
      case (#CanDBTypeBridge) "BebbBridge";
    };
  };

  private func getPkForServiceType(serviceType: Text): async Text {
    switch serviceType {
      case ("Entity") getCanDbEntityTypePK(#CanDBTypeEntity);
      case ("Bridge") getCanDbEntityTypePK(#CanDBTypeBridge);
      case (_) { throw Error.reject("Unsupported serviceType"); };
    };
  };

}