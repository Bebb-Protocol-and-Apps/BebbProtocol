import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Principal "mo:base/Principal";

module {

    /**
    * Defines the base entity that is shared accross multiple entity types such as Entities themselvse and bridges
    */
    public type BaseEntity = {
        /*
        * The ID of the Entity that is used to store it in
        * in the entity database
        */
        id : Text;
        /**
        * The timestamp in UTC (maybe) that the entity was created
        */
        creationTimestamp : Nat64;
        /**
        * The original creator of the entity.
        */
        creator : Principal;
        /**
        * The current owner of the entity
        */
        owner : Principal;
        /**
        * A human readable name? for the entity
        */
        name : Text;
        /**
        * An owner defined description for what the entity is
        */
        description : Text;
        /**
        * Keywords that are used to descripe the entity to
        * enable more efficient lookup of the entity
        */
        keywords : [Text];
        /**
        * Unknown
        */
        entitySpecificFields : Text;
        /**
        * Unknown
        */
        listOfEntitySpecificFieldKeys : [Text];
    };
};
