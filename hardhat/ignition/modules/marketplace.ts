import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ArtBidexMarketplace", (m) => {
  const ArtBidexMarketplace = m.contract("ArtBidexMarketplace", []); 
  return { ArtBidexMarketplace };
});
