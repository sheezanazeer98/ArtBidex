import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ArtBidexDeployment", (m) => {
  // Deploy ArtBidexNFT contract
  const artBidexNFT = m.contract("ArtBidexNFT", []);

  // Deploy ArtBidexMarketplace contract
  const artBidexMarketplace = m.contract("ArtBidexMarketplace", []);

  return { artBidexNFT, artBidexMarketplace };
});
