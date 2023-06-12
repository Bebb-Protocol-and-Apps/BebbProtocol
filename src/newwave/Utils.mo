import Array      "mo:base/Array";
import Blob       "mo:base/Blob";
import Buffer     "mo:base/Buffer";
import Error      "mo:base/Error";
import Nat8       "mo:base/Nat8";
import Nat32      "mo:base/Nat32";
import Principal  "mo:base/Principal";
import Text       "mo:base/Text";
import Debug      "mo:base/Debug";

import UUID "mo:uuid/UUID";
import Source "mo:uuid/Source";
import SourceAsync "mo:uuid/async/SourceV4";
//import AsyncSource "mo:uuid/async/SourceV4";
import XorShift "mo:rand/XorShift";

module {
  public func newUniqueId() : Text {
    let rr = XorShift.toReader(XorShift.XorShift64(null));
    let c : [Nat8] = [0, 0, 0, 0, 0, 0]; // TODO: Replace with identifier of canister f.e.
    let se = Source.Source(rr, c);
    let id = se.new();
    UUID.toText(id);
	};

  public func newRandomUniqueId() : async Text {
    let g = SourceAsync.Source();
    UUID.toText(await g.new());
	};
}
