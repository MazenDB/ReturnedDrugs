pragma solidity >=0.4.22;

contract Lot_Batch{
    //address BatchEA;
    string drugName;
    uint manufacturingDate;
    uint expiryDate;
    address owner;
    uint quantity;
    uint pricePerBox;
    string currentType;
    
    
    mapping (uint=>bool) drugPurchased;
    
    modifier onlyOwner{
      require(msg.sender == owner,
      "Sender not authorized."
      );
      _;
    }    
    
    event LotDispatched(address LotAddress, string DrugName, uint Quantity, uint PricePerBox, address Manufacturer);
    
    event OwnerChanged(address NewOwner, string OwnerType);

    event DrugSold(address LotAddress, uint boxNumber);
    
    constructor(string memory n, uint mDate, uint eDate, uint Q, uint price) public{
       drugName=n;
       manufacturingDate = mDate;
       expiryDate= eDate;
       owner= msg.sender;
       quantity= Q;
       pricePerBox= price;
       currentType = "Manufacturer";
       emit LotDispatched(address(this), n, Q, price, owner);
   }
   
   
   function sellDrug(uint boxNumber) public {
       require(!drugPurchased[boxNumber],
        "Drug Box Purchased"
        );
        require(expiryDate>now,
        "Drug has expired"
        );
       owner=msg.sender;
       currentType = "Patient";
        quantity--;
        drugPurchased[boxNumber]=true;
        emit DrugSold(address(this), boxNumber);
   }
   
   function changeOwner(string memory OT) public onlyOwner{
       owner=msg.sender;
       currentType = OT;
       emit OwnerChanged(owner, OT);
   }
   
}

contract ReturnedDrugsSummary{
    
    address FDA;
    
    mapping(address=>bool) ApprovedResellers;

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
    
    
    function regiterReseller(address Reseller) public onlyFDA{
        require(!ApprovedResellers[Reseller],
            "Reseller exists already"
            );
            
        ApprovedResellers[Reseller]=true;
    }
    
    function regiterCA(address CA) public onlyFDA{
        require(!ApprovedCA[CA],
            "Certification Agency exists already"
            );
            
        ApprovedCA[CA]=true;
    }
    
    function approveReturnedPackage(address EA, string memory name, uint mDate, uint eDate, uint Q, uint price,address reseller) public onlyCA {
        require(ApprovedResellers[msg.sender],
            "Reseller not approved"
            );
        returnedDrugPackages[EA]=true;
    }
    
    
}

contract ReturnedPackage{
    
    //address EA;
    string public drugName;
    uint public pricePerBox;
    address public owner;
    uint public quantity;
    uint public manufacturingDate;
    uint public expiryDate;
    string currentType;
    address public reseller;
    
    mapping (uint=>bool) drugResold;
    
    
   modifier onlyOwner{
      require(msg.sender == owner,
      "Sender not authorized."
      );
      _;
    }
    
    modifier onlyReseller{
      require(msg.sender == reseller,
      "Sender not authorized."
      );
      _;
    }
    

    event ReturnedDrugApproved(address DrugPackageAddress, string DrugName, uint Quantity, uint PricePerBox, address CertificationAgency);

    event OwnerChanged(address NewOwner, string OwnerType);

    event DrugResold(address DrugPackageAddress, uint boxNumber);

    constructor(string memory name, uint mDate, uint eDate, uint Q, uint price, address reselleradd) public{
       drugName = name;
       manufacturingDate = mDate;
       expiryDate= eDate;
       owner= msg.sender;
       quantity= Q;
       pricePerBox= price;
       currentType = "CA";
       reseller=reselleradd;
       emit ReturnedDrugApproved(address(this), drugName, quantity, pricePerBox, owner);
   }
   
   function changeOwner(string memory OT) public onlyOwner{
       owner=msg.sender;
       emit OwnerChanged(owner, OT);
   }
   
   function resellDrug(uint boxNumber) public onlyReseller{
       require(!drugResold[boxNumber],
        "Drug Box Resold"
        );
        require(expiryDate>now,
        "Drug has expired"
        );
        changeOwner("Patient");
        quantity--;
        drugResold[boxNumber]=true;
        emit DrugResold(address(this), boxNumber);
   }
   
}
