import { EthersAdapter } from '@reown/appkit-adapter-ethers'
import { mainnet, arbitrum,sepolia,polygonAmoy,hardhat } from '@reown/appkit/networks'
import type { AppKitNetwork } from '@reown/appkit/networks'

// Get projectId from https://cloud.reown.com
export const projectId = "91978e3e5e150be0d8231fa85f8db567"

if (!projectId) {
  throw new Error('Project ID is not defined')
}

export const networks = [mainnet, arbitrum,sepolia,polygonAmoy,hardhat] as [AppKitNetwork, ...AppKitNetwork[]]

export const ethersAdapter = new EthersAdapter();