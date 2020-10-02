pragma solidity =0.6.0;

contract Lot_Batch{
    //address BatchEA;
    string drugName;
    uint drugCode;
    uint manufacturingDate;
    uint expiryDate;
    address owner;
    uint quantity;
    uint pricePerBox;
    string currentType;
    
    OriginalDrugsSummary summaryContract;
    
    mapping (uint=>bool) drugPurchased;
    
    modifier onlyOwner{
      require(msg.sender == owner,
      "Sender not authorized."
      );
      _;
    }
    
    modifier onlySeller{
      require(summaryContract.sellerExists(msg.sender),
      "Sender not authorized."
      );
      _;
    } 
    
    event LotDispatched(address LotAddress, string DrugName, uint Quantity, uint PricePerBox, address Manufacturer);
    
    event OwnerChanged(address NewOwner, string OwnerType);

    event DrugSold(address LotAddress, uint boxNumber);
    
    constructor(address original, string memory n, uint dC, uint mDate, uint eDate, uint Q, uint price) public{
       drugName=n;
       drugCode=dC;
       manufacturingDate = mDate;
       expiryDate= eDate;
       owner= msg.sender;
       quantity= Q;
       pricePerBox= price;
       currentType = "Manufacturer";
       summaryContract = OriginalDrugsSummary(original);
       emit LotDispatched(address(this), n, Q, price, owner);
   }
   
   
   function sellDrug(uint boxNumber) onlyOwner onlySeller public {
       require(!drugPurchased[boxNumber],
        "Drug Box Purchased"
        );
        require(expiryDate>now,
        "Drug has expired"
        );
       //owner=msg.sender;
       //currentType = "Patient";
        quantity--;
        drugPurchased[boxNumber]=true;
        emit DrugSold(address(this), boxNumber);
   }
   
   function changeOwner(address payable newOwner, string memory OT) public onlyOwner{
       owner=newOwner;
       currentType = OT;
       emit OwnerChanged(owner, OT);
   }
   
}

contract OriginalDrugsSummary{
    
    address FDA;
    
    mapping(uint=>bool) approvedDrugs;
    
    mapping(address=>bool) approvedManufacturers;
    
    mapping(address=>bool) dispatchedLots;
    
    mapping(address=>bool) sellers;
    
    
    constructor () public{
        FDA=msg.sender;
    }
    
    modifier onlyFDA{
      require(msg.sender == FDA,
      "Sender not authorized."
      );
      _;
    }    
    
    modifier onlyManufacturer{
      require(approvedManufacturers[msg.sender],
      "Sender not authorized."
      );
      _;
    }    
    
    
    function registerDrug(uint drug) public onlyFDA{
        require(!approvedDrugs[drug],
            "Drug exists already"
            );
            
        approvedDrugs[drug]=true;
    }
    
    function registerManufacturer(address manu) public onlyFDA{
        require(!approvedManufacturers[manu],
            "Manufacturer exists already"
            );
            
        approvedManufacturers[manu]=true;
    }
    
    function registerSeller(address seller) public onlyFDA{
        require(!sellers[seller],
            "Seller exists already"
            );
            
        sellers[seller]=true;
    }
    
    function approveDispatched(address LotAddress, uint DrugCode) public onlyManufacturer {
        require(approvedDrugs[DrugCode],
            "Drug not approved"
            );
        dispatchedLots[LotAddress]=true;
    }
    
    function sellerExists(address s) public view returns(bool){
        return sellers[s];
    }
    
}

contract ReturnedDrugsSummary{
    
    address FDA;
    
    struct reseller_type
    {
      bool exists;
      uint reputation;
      uint deposit;
    }
    
    mapping(address=>reseller_type) public ApprovedResellers;

    mapping(address=>bool) ApprovedCA;
    
    mapping(address=>bool) returnedDrugPackages;
    
    constructor () public{
        FDA=msg.sender;
    }
    
    modifier onlyFDA{
      require(msg.sender == FDA,
      "Sender not authorized."
      );
      _;
    }    
    
    modifier onlyCA{
      require(ApprovedCA[msg.sender],
      "Sender not authorized."
      );
      _;
    }    
    
    
    function registerReseller(address reseller) public onlyFDA{
        require(!ApprovedResellers[reseller].exists,
            "Reseller exists already"
            );
            
        ApprovedResellers[reseller].exists=true;
        ApprovedResellers[reseller].reputation=80;
    }
    
    function registerCA(address CA) public onlyFDA{
        require(!ApprovedCA[CA],
            "Certification Agency exists already"
            );
            
        ApprovedCA[CA]=true;
    }
    
    function approveReturnedPackage(address ReturnedPackageEA) public onlyCA {
        require(ApprovedCA[msg.sender],
            "Certification Authority not approved"
            );
        returnedDrugPackages[ReturnedPackageEA]=true;
    }
    
    function resellerExists(address r) external view returns(bool){
        return ApprovedResellers[r].exists;
    }
    
    function resellerRep(address r) external view returns(uint){
        return ApprovedResellers[r].reputation;
    }
    
    function setResellerDeposit(address r, uint d) external{
        ApprovedResellers[r].deposit=d;
    }
    
    function setResellerRep(address res, uint rep) external{
        ApprovedResellers[res].reputation=rep;
    }
    
    
}

contract ReturnedPackage {
    
    //address EA;
    string public drugName;
    uint public price;
    address payable owner;
    uint public quantity;
    uint public manufacturingDate;
    uint public expiryDate;
    string currentType;
    address payable public reseller;
    address public lot_batchAddress;
    uint minimumRep;
    mapping (uint=>bool) drugResold;
    bool auctionOpen;
    uint closingTime;
    address returnedSummaryAddress;
    ReturnedDrugsSummary R;
    
   modifier onlyOwner{
      require(msg.sender == owner,
      "Sender not authorized."
      );
      _;
    }
    
    modifier onlyApprovedReseller{
      require(msg.sender == reseller,
      "Sender not authorized."
      );
      _;
    }
    
    modifier onlyReseller{
      require(R.resellerExists(msg.sender),
      "Sender not authorized."
      );
      _;
    }
    
    event ReturnedDrugApproved(address DrugPackageAddress, string DrugName, uint Quantity, uint Price, address CertificationAgency);

    event OwnerChanged(address NewOwner, string OwnerType);

    event DrugResold(address DrugPackageAddress, uint boxNumber);
    
    event AuctionStarted(uint closingTime,uint startPrice, uint MinRep);
    
    event BidPlaced(address ResellerAddress, uint price);

    event AuctionClosed(address ResellerAddress, uint Price);


    constructor(string memory name, uint mDate, uint eDate, uint Q, address lot,address summaryAddress) public{
       drugName = name;
       manufacturingDate = mDate;
       expiryDate= eDate;
       owner= msg.sender;
       quantity= Q;
       currentType = "CA";
       lot_batchAddress=lot;
       auctionOpen=false;
       returnedSummaryAddress=summaryAddress;
        R = ReturnedDrugsSummary(summaryAddress);

       emit ReturnedDrugApproved(address(this), drugName, quantity, price, owner);
   }
   
   function changeOwner(address payable newOwner, string memory OT) private onlyOwner{
       owner=newOwner;
       emit OwnerChanged(owner, OT);
   }
   
   function resellDrug(uint boxNumber) public onlyApprovedReseller{
       require(!drugResold[boxNumber],
        "Drug Box Resold"
        );
        require(expiryDate>now,
        "Drug has expired"
        );
        //changeOwner("Patient");
        quantity--;
        drugResold[boxNumber]=true;
        emit DrugResold(address(this), boxNumber);
   }
   
   function startAuction(uint cTime,uint startPrice,uint minRep) payable onlyOwner public{
        require(auctionOpen==false,
        "Auction is open"
        );
        require(cTime>now,
        "Closing time cannot be in the past"
        );
        auctionOpen=true;
        minimumRep=minRep;
        price=startPrice;
        closingTime=cTime;
        emit AuctionStarted(closingTime,startPrice,minRep);

    }
    
    function placeBid(uint newPrice) payable onlyReseller public{
        require(R.resellerExists(msg.sender),
        "Entered address does not refer to an Approved Resller"
        );
        require(auctionOpen==true,
        "Auction is closed"
        );
        require(newPrice>price,
        "Please place a higher bid"
        );
        require(msg.value==newPrice,
        "Insufficient Deposit"
        );
        require(R.resellerRep(msg.sender)>=minimumRep,
        "Minimum Reputation requirement not met"
        );
        if(reseller!=address(0)){
            R.setResellerDeposit(reseller,0);
            reseller.transfer(price);
        }
        R.setResellerDeposit(reseller,msg.value);
        price=newPrice;
        reseller=msg.sender;
        emit BidPlaced(msg.sender, newPrice);
        
    }
    
    function contractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function closeAuction() onlyOwner public{
        require(auctionOpen==true,
        "Auction is closed"
        );
        require(closingTime<now,
        "Auction cannot be closed at this time"
        );
        require(reseller!=address(0),
        "No bids have been placed"
       );
        auctionOpen=false;
        reseller.transfer(price);
        R.setResellerDeposit(reseller,0);
        emit AuctionClosed(reseller, price);

    }
   
}

contract Reputation{
    
    ReturnedDrugsSummary R;
    address owner;
    uint cr;
    uint constant adjusting_factor = 4;

    event ReputationUpdated(address reseller, uint rep_score);

       modifier onlyOwner{
      require(msg.sender == owner,
      "Sender not authorized."
      );
      _;
    }    
    
    struct patient{
        mapping(address=>bool) resellers;
        mapping(address=>bool) status;
    }
    
    mapping(address=>patient) patientFeedback;
    
    constructor(address summaryAddress) public{
           R = ReturnedDrugsSummary(summaryAddress);
           owner=msg.sender;
   }
   
    function feedback (address reseller, bool transactionSuccessful) public {
        require(!patientFeedback[msg.sender].resellers[reseller],
        "Patient has already provided feedback for this reseller"
        );
        require(R.resellerExists(reseller),
        "Reseller Address is incorrect"
        );
        patientFeedback[msg.sender].resellers[reseller]=true;
        patientFeedback[msg.sender].status[reseller]=transactionSuccessful;
        //calculateRep(reseller);
    }
    
    function calculateRep (address reseller) external {
        
        if(patientFeedback[msg.sender].status[reseller]){
            cr = (R.resellerRep(reseller)*95)/(4*adjusting_factor);
            cr /= 100;
            R.setResellerRep(reseller,R.resellerRep(reseller)+cr);
        }
        else{

            cr = (R.resellerRep(reseller)*95)/(4*(10-adjusting_factor));
            cr /= 100;
            R.setResellerRep(reseller,R.resellerRep(reseller)-cr);
        }
        if (R.resellerRep(reseller)<0){
            R.setResellerRep(reseller,0);
        }
        else if (R.resellerRep(reseller)>100){
            R.setResellerRep(reseller,100);
        }
        
        emit ReputationUpdated(reseller, R.resellerRep(reseller));

   }
}
