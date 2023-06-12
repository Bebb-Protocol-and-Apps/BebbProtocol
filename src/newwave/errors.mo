module {
    public type NewWaveError = {
        #Unauthorized : Text;
        #OwnerNotFound;
        #EntityNotFound;
        #BridgeNotFound;
        #OperatorNotFound;
        #TokenNotFound;
        #ExistedNFT;
        #SelfApprove;
        #SelfTransfer;
        #TxNotFound;
        #Other : Text;
    }
}