pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721MetadataMintable.sol";

contract DataTraceability
    is Initializable, ERC721, ERC721Enumerable, ERC721MetadataMintable
{
    address public owner;

    struct DataInfo {
        address   dataId;
        address   provider;
        uint64    genTime;
        bytes32   hash;
        uint16    generation;
        uint256[] parentsDataId;
        bool      isActive;
    }

    struct TraceInfo {
        uint256 traceId;
        address dataId;
        address accessor;
        AccessAction accessAction;
        uint64  accessTime;
        address toAddress;
        address fromAddress;
        bool    isActive;
        bytes32 message;
    }

    enum AccessAction { Created, Sent, Received, Analyzed, Result, Deleted }

    mapping(address => DataInfo) private myDataInfo;      // data_id에 해당하는 개별 data 세부 정보 (dataId => dataInfo)
    mapping(address => uint256[]) private myTraceIdList;  // dataId => traceId[]
    mapping(uint256 => TraceInfo) private myTraceInfo;    // traceId => traceInfo

    modifier onlyOwner {
      require (msg.sender == owner, "ERROR_NOT_OWNER");
      _;
    }

    event DataInfoCreated (
      address   dataId,
      address   indexed provider,
      uint64    genTime,
      bytes32   hash,
      uint16    generation,
      uint256[] parentsDataId
    );

    event TraceInfoCreated (
      address      dataId,
      uint256      traceId,
      AccessAction accessAction,
      uint64       accessTime,
      address      toAddress,
      address      fromAddress,
      bytes32      message
    );

    function initialize(
        string memory name,
        string memory symbol,
        address[] memory minters
    )
    public
    initializer
    {
        owner = msg.sender;
        
        ERC721.initialize();
        ERC721Enumerable.initialize();
        ERC721Metadata.initialize(name, symbol);
        ERC721MetadataMintable.initialize(address(this));

        _removeMinter(address(this));

        for (uint256 i = 0; i < minters.length; ++i) {
            _addMinter(minters[i]);
        }
    }

    function createDataInfo(
        address _dataId,
        address _provider,
        uint64 _genTime,
        bytes32 _hash,
        uint16 _generation,
        uint256[] memory _parentsDataId)
        public
        onlyMinter
    {
        require(myDataInfo[_dataId].isActive == false, "ERROR_DATA_ID_EXISTS");
        require(_provider != address(0), "ERROR_ZERO_ADDRESS");

        DataInfo memory newDataInfo;
        newDataInfo.dataId        = _dataId;
        newDataInfo.provider      = _provider;
        newDataInfo.genTime       = _genTime;
        newDataInfo.hash          = _hash;
        newDataInfo.generation    = _generation;
        newDataInfo.parentsDataId = _parentsDataId;
        newDataInfo.isActive      = true;
        myDataInfo[_dataId]       = newDataInfo;

        //Token 발행
        mintWithTokenURI(_provider, uint256(_dataId), "");

        // event 생성
        emit DataInfoCreated(_dataId, _provider, _genTime, _hash, _generation, _parentsDataId);
    }

    function getDataInfo(address _dataId) public view returns (
        address,
        address,
        uint64,
        bytes32,
        uint16,
        uint256[] memory
    ){
        require(myDataInfo[_dataId].isActive == true, "ERROR_DATA_ID_NOT_EXISTS");

        DataInfo memory dataInfo = myDataInfo[_dataId];
        return (dataInfo.dataId, dataInfo.provider, dataInfo.genTime, dataInfo.hash, dataInfo.generation, dataInfo.parentsDataId);
    }

    function getDataInfoByOwnerIndex(address _dataOwner, uint256 _dataIndex) public view returns (
        address,
        address,
        uint64,
        bytes32,
        uint16,
        uint256[] memory
    ) {
        uint256 data_id = tokenOfOwnerByIndex(_dataOwner, _dataIndex);
        require(myDataInfo[address(uint160(data_id))].isActive == true, "ERROR_DATA_ID_NOT_EXISTS");

        DataInfo memory dataInfo = myDataInfo[address(uint160(data_id))];
        return (dataInfo.dataId, dataInfo.provider, dataInfo.genTime, dataInfo.hash, dataInfo.generation, dataInfo.parentsDataId);
    }

    function createTraceInfo(address _dataId, uint256 _traceId,  AccessAction _accessAction, uint64 _accessTime, address _toAddress, address _fromAddress, bytes32 _message) public {

        // dataId가 존재하는지 검사
        require(myDataInfo[_dataId].isActive == true, "ERROR_DATA_ID_NOT_EXISTS");
        // dataId에 해당하는 traceId가 존재하는지 검새
        require(myTraceInfo[_traceId].isActive == false, "ERROR_TRACE_ID_EXISTS");
        // access type parameters 검사
        require(AccessAction.Result >= _accessAction, "ERROR_ACCESS_TYPE_PARAMETER");

        TraceInfo memory newTraceInfo;
        newTraceInfo.dataId       = _dataId;
        newTraceInfo.traceId      = _traceId;
        newTraceInfo.accessor     = msg.sender;
        newTraceInfo.accessAction = AccessAction(_accessAction);
        newTraceInfo.accessTime   = _accessTime;
        newTraceInfo.toAddress    = _toAddress;
        newTraceInfo.fromAddress  = _fromAddress;
        newTraceInfo.isActive     = true;
        newTraceInfo.message      = _message;

        myTraceInfo[_traceId] = newTraceInfo;
        myTraceIdList[_dataId].push(_traceId);

        emit TraceInfoCreated(_dataId, _traceId, _accessAction, _accessTime, _toAddress, _fromAddress, _message);
    }

    function getTraceInfo(uint256 _traceId) public view returns (
        uint256,
        address,
        address,
        AccessAction,
        uint64,
        address,
        address
    ) {
        // traceId가 존재하는지 검사
        require(myTraceInfo[_traceId].isActive == true, "ERROR_TRACE_ID_NOT_EXISTS");
        TraceInfo memory ti = myTraceInfo[_traceId];

        return (ti.traceId, ti.dataId, ti.accessor, ti.accessAction, ti.accessTime, ti.toAddress, ti.fromAddress);
    }

    function getTraceInfoByTraceIndex(address _dataId, uint256 _traceIndex) public view returns (
        uint256,
        address,
        address,
        AccessAction,
        uint64,
        address,
        address
    ) {
        // data id가 존재하는지 검사
        require(myDataInfo[_dataId].isActive == true, "ERROR_DATA_ID_NOT_EXISTS");
        // trace list가 index내에 존재하는지 검사
        require(myTraceIdList[_dataId].length > 0, "ERROR_TRACE_NOT_EXISTS");
        require(myTraceIdList[_dataId].length > _traceIndex, "ERROR_INVALID_TRACE_INDEX");

        uint256[] memory traceLists = myTraceIdList[_dataId];
        TraceInfo memory ti = myTraceInfo[traceLists[_traceIndex]];

        return (ti.traceId, ti.dataId, ti.accessor, ti.accessAction, ti.accessTime, ti.toAddress, ti.fromAddress);
    }

    function getTraceCount(address _dataId) public view returns (uint256) {
        // data id가 존재하는지 검사
        require(myDataInfo[_dataId].isActive == true, "ERROR_DATA_ID_NOT_EXISTS");
        // trace list가 index내에 존재하는지 검사
        require(myTraceIdList[_dataId].length >= 0, "ERROR_TRACE_NOT_EXISTS");

        return (myTraceIdList[_dataId].length);
    }

    function addMinter(address account) public {
       _addMinter(account);
    }

    function getOwner() public view returns (address) {
      return owner;
    }
}