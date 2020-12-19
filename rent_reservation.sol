/*
    This is a for rent and reserve book in a blockchain on Etherium.
    This demonstrates various function.

*/

pragma solidity ^0.6.0;

contract Bookrent {
    address payable seller; // This is the address for the seller

    constructor() public {
        seller = msg.sender; //the value is initilized to the seller
        productIndex = 0; //index to count the number of entries---here the different account
    }

    enum ProductStatus {Open, Onrent, Noqueue, Unavailable}
    enum ProductCondition {New, Used}

    uint256 public productIndex;

    mapping(address => mapping(uint256 => Product)) private stores;
    mapping(uint256 => address) private productIdInStore;
    mapping(address => mapping(uint256 => uint256)) private time;
    mapping(uint256 => mapping(uint256 => address payable)) private queue;

    uint256 first = 0;
    uint256 last = 0;

    struct Product {
        uint256 id;
        string name;
        string imageLink;
        string descLink;
        uint256 ISBN;
        uint256 num_days;
        uint256 amount;
        string location;
        ProductStatus status;
        ProductCondition condition;
    }

    modifier sellerCheck() {
        require(seller == msg.sender, "Only owner use this functionality!");
        _;
    }

    modifier availabilitycheck(uint256 _productId) {
        require(
            now > time[queue[first][_productId]][_productId],
            "Currently being rented, You can reserve the book! "
        );

        require(
            stores[productIdInStore[_productId]][_productId].status ==
                ProductStatus.Open ||
                last == first ||
                stores[productIdInStore[_productId]][_productId].status ==
                ProductStatus.Noqueue,
            "Not Unavailable, you still can reserve!!"
        );
        require(
            (msg.value / 1 ether) ==
                stores[productIdInStore[_productId]][_productId].amount,
            "Amount not matched/ No amount entered!!!"
        );
        _;
    }

    function addBookToStore(
        string memory _name,
        string memory _imageLink,
        string memory _descLink,
        string memory _location,
        uint256 _ISBN,
        uint256 _num_days,
        uint256 _amount,
        uint256 _productCondition
    ) public sellerCheck {
        Product memory product = Product(
            productIndex,
            _name,
            _imageLink,
            _descLink,
            _ISBN,
            _num_days,
            _amount,
            _location,
            ProductStatus.Open,
            ProductCondition(_productCondition)
        );

        stores[msg.sender][productIndex] = product;
        productIdInStore[productIndex] = msg.sender;

        productIndex += 1;
    }

    function get_books(uint256 _productId)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            ProductStatus,
            ProductCondition
        )
    {

            Product memory product
         = stores[productIdInStore[_productId]][_productId];
        return (
            product.id,
            product.name,
            product.imageLink,
            product.descLink,
            product.location,
            product.ISBN,
            product.num_days,
            product.amount,
            product.status,
            product.condition
        );
    }

    address payable buyer;

    function setByuerAddress() public payable {
        buyer = msg.sender;
    }

    /*  function make_available_again(uint _productId) public sellerCheck(){
        stores[productIdInStore[_productId]][_productId].status = ProductStatus.Open;
    }*/

    function reserve_checkout(uint256 _productId) public payable {
        require(
            now > time[queue[first][_productId]][_productId],
            "Currently being rented. Have time to return the book!"
        );
        require(!(first >= last), " Noone is in the queue!!");
        require(
            (msg.value / 1 ether) ==
                stores[productIdInStore[_productId]][_productId].amount,
            "No amount entered!!!"
        );

        first += 1;
        if (first == last) {
            stores[productIdInStore[_productId]][_productId]
                .status = ProductStatus.Noqueue;
        }

        buyer = queue[first][_productId];
        require(msg.sender == buyer, "It's somebody else turn");
        seller.transfer(msg.value);

        time[buyer][_productId] =
            now +
            stores[productIdInStore[_productId]][_productId].num_days;
        queue[first][_productId] = buyer; //the renter/buyer Currently renting the book
    }

    function enqueue(uint256 _productId) internal {
        last += 1;
        queue[last][_productId] = msg.sender;
    }

    function reserve_book(uint256 _productId) public {
        require(
            !(stores[productIdInStore[_productId]][_productId].status ==
                ProductStatus.Open),
            "Noobody has rented the book!, go to rent!"
        );
        enqueue(_productId);
        // stores[productIdInStore[_productId]][_productId].status = ProductStatus.Onrent;
    }

    function rent(uint256 _productId)
        public
        payable
        availabilitycheck(_productId)
    {
        stores[productIdInStore[_productId]][_productId].status = ProductStatus
            .Open;
        if (
            (msg.value / 1 ether) ==
            stores[productIdInStore[_productId]][_productId].amount
        ) {
            seller.transfer(msg.value);

            queue[first][_productId] = msg.sender;
            stores[productIdInStore[_productId]][_productId]
                .status = ProductStatus.Onrent;

            time[msg.sender][_productId] =
                now +
                stores[productIdInStore[_productId]][_productId].num_days;
        }
    }
}
