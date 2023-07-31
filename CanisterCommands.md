dfx canister call newwave create_entity "(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; })"
dfx canister call newwave get_entity '("D6C65674-91BE-170D-BCC0-000000000000")'
dfx canister call newwave create_bridge '(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; _bridgeType = variant {OwnerCreated}; _fromEntityId = "20621F98-91B0-170D-B0F5-000000000000"; _toEntityId = "D6C65674-91BE-170D-BCC0-000000000000";  })'
dfx canister call newwave get_bridge '("76CBDF90-9246-170D-9C79-000000000000")'
dfx canister call newwave get_bridge_ids_by_entity_id '("D6C65674-91BE-170D-BCC0-000000000000", true, true, true)'
dfx canister call newwave get_bridges_by_entity_id '("D6C65674-91BE-170D-BCC0-000000000000", true, true, true)'
 dfx canister call newwave create_entity_and_bridge '(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; }, record { _internalId = null; _creator = null; _entityType = variant {Webasset}; _bridgeType = variant {OwnerCreated}; _fromEntityId = "20621F98-91B0-170D-B0F5-000000000000"; _toEntityId = "D6C65674-91BE-170D-BCC0-000000000000";  })'
 dfx canister call newwave get_bridged_entities_by_entity_id '("D6C65674-91BE-170D-BCC0-000000000000", true, true, true)'
 dfx canister call newwave get_entity_and_bridge_ids '("D6C65674-91BE-170D-BCC0-000000000000", true, true, true)'

Call from CLI (IC):
 first deploy to IC mainnet: dfx deploy --network ic
 dfx canister --network ic call newwave create_entity "(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; })"
 dfx canister --network ic call newwave get_entity '("C923CD99-92E1-170D-908C-000000000000")'
 ## Call from CLI (local):
 
 dfx canister --network ic call newwave create_bridge '(record { _internalId = null; _creator = null; _entityType = variant {Webasset}; _bridgeType = variant {OwnerCreated}; _fromEntityId = "01A90437-92F8-170D-9F6C-000000000000"; _toEntityId = "C923CD99-92E1-170D-908C-000000000000";  })'
 dfx canister --network ic call newwave get_bridge '("E64582AA-9302-170D-A43D-000000000000")'
 dfx canister --network ic call newwave get_bridge_ids_by_entity_id '("C923CD99-92E1-170D-908C-000000000000", true, true, true)'
dfx canister --network ic call newwave get_bridges_by_entity_id '("C923CD99-92E1-170D-908C-000000000000", true, true, true)'
dfx canister --network ic call newwave create_entity_and_bridge '(record { _internalId = null; _creator = null; _entityType = variant {Person}; }, record { _internalId = null; _creator = null; _entityType = variant {Webasset}; _bridgeType = variant {OwnerCreated}; _fromEntityId = "C923CD99-92E1-170D-908C-000000000000"; _toEntityId = "";  })'
 dfx canister --network ic call newwave get_bridged_entities_by_entity_id '("C923CD99-92E1-170D-908C-000000000000", true, true, true)'
 dfx canister --network ic call newwave get_entity_and_bridge_ids '("C923CD99-92E1-170D-908C-000000000000", true, true, true)'

Top up cycles:
dfx identity --network=ic get-wallet
dfx wallet --network ic balance
dfx canister --network ic status newwave
dfx canister --network ic --wallet 3v5vy-2aaaa-aaaai-aapla-cai deposit-cycles 3000000000000 newwave

2022-11-15: topped up 3.3T cycles, has balance of 7.2T (2023-02-20: basically hasn't changed, 2023-07-05: 7.186)

Fund wallet with cycles (from ICP): https://medium.com/dfinity/internet-computer-basics-part-3-funding-a-cycles-wallet-a724efebd111