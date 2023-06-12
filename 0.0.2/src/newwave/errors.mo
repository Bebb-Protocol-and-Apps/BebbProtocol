module {
    public type NewWaveError = {
        #Unauthorized;
        #OwnerNotFound;
        #OperatorNotFound;
        #TokenNotFound;
        #ExistedNFT;
        #SelfApprove;
        #SelfTransfer;
        #TxNotFound;
        #Other : Text;
    }
}