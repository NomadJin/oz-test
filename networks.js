const HDWalletProvider = require('@truffle/hdwallet-provider');

const dtsAdminPrivateKey = '18ec66b481a0d37d612db26541682079f9a165c7d76924dc70ece8bd5ff5a0ec'

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 7545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },
    chainztest: {
      provider: () => new HDWalletProvider(dtsAdminPrivateKey, 'https://besutest.chainz.network/'),
      networkId: '2020',
      gas: 1E7,
      gasPrice: 0
    }
  },
};
