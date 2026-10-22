# -*- coding: utf-8 -*-
# Directorio maestro de instituciones de liquidez RWA (Google Doc "RWA_Master_Liquidity_Institution_List_20260823")
# + adiciones del brief del 9 de agosto. Transcrito verbatim: (nombre, tipo_detalle, region, tesis)
import json
MASTER="RWA_Master_Liquidity_Institution_List_20260823"
BRIEF="RWA_Liquidity_Institutions_Brief_20260809"
C={}
C["Global & Regional Banks"]=[
("JPMorgan Chase / Kinexys","Global bank","US / Global","Runs the Kinexys (formerly Onyx) blockchain platform for tokenized deposits (JPMD), tokenized MMF shares (MONY, JLTXX) and the Fund Flow subscription/redemption network; hosts Schroders' tokenized USD MMF share class (Aug 10) — the deepest bank-run tokenization infrastructure tracked."),
("Goldman Sachs","Global bank","US / Global","Operates its Digital Asset Platform (GS DAP); launched a tokenized real-estate fund with LRC Group, and partners with Ownera, Apex Group and Archax on distribution/infrastructure."),
("Citigroup","Global bank","US / UK / Singapore / Hong Kong","Citi Token Services (CTS) confirmed live across four markets, a stated top priority for CEO Jane Fraser; partners include Kaleido, SIX and Siam Commercial Bank."),
("HSBC","Global bank","UK / Asia / Global","Investor in Marketnode; added US coverage for tokenized deposits in 2026; participant in the UK Finance tokenized-deposit pilot."),
("Standard Chartered","Global bank","UK / Asia / Africa / Middle East","Active across multiple Asia, Africa and Middle East tokenization pilots and the UK Finance tokenized-deposit initiative."),
("DBS Bank","Bank","Singapore","Piloting tokenized gold via DDEx institutional listing; targeting H2 2026 launch (still pre-launch as of Aug 18)."),
("UBS","Global bank","Switzerland / Global","Named DigiFT-ecosystem partner and broadly active in tokenized fund distribution."),
("Deutsche Bank","Global bank","Germany / Europe","Active in European tokenization infrastructure alongside SG-FORGE and Deutsche Bundesbank."),
("SMBC","Bank","Japan","Regional Asian bank active in tokenization pilots."),
("MUFG","Bank","Japan","Launched a JGB repo on-chain settlement proof-of-concept via Canton Network (2026)."),
("Morgan Stanley","Bank / broker-dealer","US","Reportedly building a tokenized-asset ATS/wallet targeted for H2 2026 (still pre-launch as of Aug 21)."),
("Wells Fargo","Bank","US / UK","Confirmed (Aug 4) tokenized deposits launching Fall 2026 for corporate/commercial clients (USD/GBP corridor first), integrating with TCH's shared network."),
("Bank of America","Bank","US","Named member of The Clearing House's shared tokenized-deposit consortium."),
("PNC Bank","Bank","US","TCH consortium member."),
("Truist","Bank","US","TCH consortium member."),
("U.S. Bank","Bank","US","TCH consortium member."),
("TD Bank","Bank","US / Canada","TCH consortium member."),
("BMO","Bank","Canada / US","TCH consortium member."),
("Citizens Financial Group","Bank","US","TCH consortium member."),
("Fifth Third Bank","Bank","US","TCH consortium member."),
("KeyBank","Bank","US","TCH consortium member."),
("Regions Financial","Bank","US","TCH consortium member."),
("Huntington National Bank","Bank","US","TCH consortium member."),
("Santander","Bank","Spain / Global","Confirmed (Aug 21) as the 17th named TCH consortium member; also part of the UK Finance pilot."),
("Maybank","Bank","Malaysia","Named participant in DTCC's live tokenization pilot."),
("BNP Paribas","Global bank","France / Global","Named participant in DTCC's live tokenization pilot."),
("Charles Schwab","Brokerage","US","Named participant in DTCC's live tokenization pilot and Plume's DTCC working group."),
("Itaú Unibanco","Bank","Brazil","Brazil's largest bank; running a fixed-income/fund tokenization pilot with OpenAssets under the ANBIMA regulatory framework."),
("First Abu Dhabi Bank","Bank","UAE","Part of a UAE consortium (with International Holding Company and Sirius International Holding) developing the DDSC dirham-pegged stablecoin for ADGM tokenization settlement."),
("Africa Finance Corporation","Pan-African DFI","Africa","Priced a CHF 350M digital bond on SIX/SDX — first African issuer, and the largest international issuer, in that market."),
("SBI Holdings / SBI Group","Diversified financial conglomerate","Japan","Launched \"SBI Onchain\" with DigiFT for institutional RWA access — first major Japanese financial group named in this tracker."),
]
C["Bank Consortia, Market Infrastructure, Clearing & Ratings"]=[
("The Clearing House (TCH)","Bank-owned payments consortium","US","17-bank consortium building a shared tokenized-deposit network; timeline slipped to H1 2027."),
("Euroclear","Securities settlement infrastructure","Belgium / Europe","Investor in Marketnode alongside HSBC."),
("Banque de France","Central bank","France","Runs tokenization / wholesale-CBDC experiments."),
("SG-FORGE","Tokenization arm of Société Générale","France","Active European tokenization issuer."),
("Deutsche Bundesbank","Central bank","Germany","Active in European tokenization pilots."),
("UK Finance","Banking trade body","UK","Runs a tokenized-deposit pilot with Barclays, HSBC, Lloyds, NatWest, Nationwide and Santander (conclusion still pending)."),
("Komgo","Trade-finance blockchain consortium","Switzerland","Bank-backed platform for trade-finance tokenization."),
("DTCC","US central securities depository","US","Ran a live tokenization pilot (~40 institutions incl. Citadel Securities, BNP Paribas, Schwab, Apex Clearing, Alpaca, Tradeweb, Maybank, Invesco); October 2026 full-launch scope pending."),
("Chainlink","Oracle / interoperability infrastructure","Global","Powers Caliber's Automated Compliance Engine for tokenized CRE; Collateral AppChain targeted for Q4 2026."),
("Nasdaq","Exchange operator","US","Agreed (Aug 12) to acquire LeveL Markets into a new \"Digital Liquidity Networks\" division combining tokenization with 24/7 trading; also runs the Nasdaq-Talos tokenized-collateral rollout (~$35B target)."),
("LeveL Markets","Alternative trading system (ATS)","US","3rd-largest US ATS (~2,500 institutional clients), being acquired by Nasdaq."),
("21X","Regulated tokenization trading venue","EU","EU-licensed venue for tokenized securities trading."),
("Talos","Institutional trading infrastructure","US","Partnering with Nasdaq on tokenized-collateral infrastructure."),
("Digital Asset / Canton Network","Institutional blockchain network","US / Global","Hosts MUFG's JGB repo PoC and Northern Trust's tokenized custody."),
("Broadridge Financial Solutions","Fintech / market infrastructure","US","Distributed Ledger Repo processed $8.0T in July 2026 (392% YoY growth); integrates governance for Ondo's custodial tokenized-securities offering."),
("Marketnode","Market infrastructure JV (Temasek / SGX)","Singapore","HSBC- and Euroclear-backed; tokenizing BNY Investments (Mellon) funds on Stellar via its Fundnode platform."),
("Moody's Ratings","Credit rating agency","US / Global","First major rating agency active on tokenized/on-chain instruments."),
("Injective","Layer-1 blockchain","Global","Became an SEC-registered transfer agent (Aug 19) via its institutional services arm."),
("Quant","Interoperability infrastructure","UK","Provides interoperability rails for tokenized-asset networks."),
("NYSE","Exchange operator","US","Reportedly developing an on-chain platform; no firm launch date surfaced yet."),
]
C["Asset Managers, Funds & Sovereign Wealth"]=[
("BlackRock","Asset manager","US / Global","BUIDL tokenized MMF (~$2.68B TVL); debuted tokenized access to $311B of European money-market funds (Aug 4)."),
("Franklin Templeton","Asset manager","US / Global (Asia via DigiFT)","BENJI tokenized MMF (~$1.72B TVL, fund ~$726M); SEC granted custody relief for onchain cash management; BENJI now distributed into Asia through DigiFT (May 2026)."),
("Vanguard","Asset manager","US","Named among major managers exploring tokenized fund infrastructure."),
("Invesco","Asset manager","US","Tokenized QQQ as DTCC-pilot collateral; filed a tokenized stablecoin-reserve MMF; took over Superstate's USTB fund (~$967M AUM)."),
("Apollo Global Management","Alternative asset manager","US / Global","ACRED diversified credit fund distributed via Securitize into Asia through HashKey Exchange's Wealth Management channel."),
("Hamilton Lane","Private-markets asset manager","US / Global — new TRON venue","Senior Credit Opportunities Fund (HLSCOPE) tokenized via Securitize became the first Securitize product issued on TRON (June 2026, ~$4.28M AUM, ~5.87% advertised yield)."),
("Aviva Investors","Asset manager","UK","Active in European tokenized fund initiatives."),
("State Street","Asset servicer / custodian","US / Global","Announced tokenized fund servicing launch from Luxembourg by year-end 2026."),
("Fidelity International","Asset manager","UK / Global","Runs the FILQ tokenized fund on Ethereum."),
("VanEck","Asset manager","US","Active tokenized-product issuer."),
("WisdomTree","Asset manager","US","Tokenized fund issuer across Ethereum and Stellar."),
("Neuberger Berman","Asset manager","US / Global","Launched first tokenized high-yield bond fund (HINC, Aug 18) via Securitize, bringing its $230B fixed-income platform onchain across Sui, Avalanche, Ethereum and Solana."),
("Janus Henderson","Asset manager","US / UK","Sponsors JAAA (AAA CLO) and JTRSY (Treasury) tokenized funds covered by Symbiotic's Liquid Lane instant-liquidity facility."),
("New York Life Investment Management (NYLIM)","Asset manager (insurance-affiliated)","US","Sponsors HYB tokenized high-yield bond fund on the same Symbiotic facility — first insurance-affiliated asset manager entrant."),
("Federated Hermes","Asset manager","US","Participant in the BNY-Goldman mirrored-tokenization MMF subscription platform."),
("Wellington Management","Global asset manager","US / Global (via Singapore)","Sub-manages a tokenized US Treasury strategy distributed through DigiFT's regulated exchange."),
("Khazanah","Sovereign wealth fund","Malaysia","Piloted RM100M (~$25M) tokenized sukuk with Securities Commission Malaysia — first named SWF and first tokenized-sukuk instrument tracked."),
("Schroders","Asset manager","UK / Global","First global asset manager approved for a tokenized USD MMF share class on JPMorgan's Kinexys platform (Aug 10)."),
("Baillie Gifford","Asset manager","UK","Launched a UK-regulated tokenized fund with BNY Mellon under the FCA's PS26/7 framework."),
]
C["Custodians"]=[
("Anchorage Digital","Federally chartered digital-asset bank / custodian","US","Partnered with Real Finance (June 2026) to pair EVM tokenization infrastructure with regulated custody, treasury and settlement across private credit, funds, real estate and structured products."),
("Fireblocks","Digital-asset custody / infrastructure","US / Global","Widely used custody/infrastructure layer across tokenization platforms."),
("BitGo","Digital-asset custodian","US","Partnered with OTC Markets Group for tokenized-securities trading on its SEC-regulated OTC Link ATS (150+ broker-dealers)."),
("Zodia Custody","Institutional custodian","UK","Bank-backed custodian (Standard Chartered-founded) serving institutional tokenized-asset clients."),
("Komainu","Institutional custodian","UK / Global","Nomura/Ledger/CoinShares-backed custodian active in institutional digital-asset custody."),
("BNY (Bank of New York Mellon)","Custodian bank / asset servicer","US / Global","Custody/fund-servicing across multiple platforms; new role as investment manager for DigiFT's tokenized US equity income fund (bEQTY); tokenizes BNY Investments funds via Marketnode/Stellar; UK-regulated fund with Baillie Gifford."),
("Sygnum Bank","Digital-asset bank / custodian","Switzerland","Regulated digital-asset bank active in tokenized custody and issuance."),
("Citco","Fund administrator","Global","Fund administration for tokenized fund structures."),
]
C["Market Makers, OTC Desks & Liquidity Providers"]=[
("Galaxy Digital","Digital-asset merchant bank","US","Institutional liquidity and capital-markets provider active in RWA tokenization."),
("Hidden Road","Prime broker / liquidity provider","US / Global","Prime brokerage and liquidity services for digital and tokenized assets."),
("Wintermute","Market maker / OTC desk","UK / Global","Cleared SEC/FINRA broker-dealer registration (Aug 6); launched an institutional tokenized-gold OTC desk, projecting the tokenized-gold market to reach $15B in 2026."),
("GSR","Market maker / OTC desk","US / Global","Runs an OTC liquidity desk for DigiFT's tokenized-RWA marketplace (~$13.4B addressable market)."),
("Cumberland (DRW)","OTC liquidity provider","US","Institutional OTC digital-asset liquidity desk."),
("Flow Traders","ETP market maker","Netherlands","Launched a 24/7 OTC liquidity service for tokenized stocks, gold and money-market funds."),
("B2C2","OTC liquidity provider","UK / Global","Institutional OTC crypto/tokenized-asset liquidity provider."),
("Citadel Securities","Market maker","US","Named market-maker participant in DTCC's live tokenization pilot."),
]
C["Crypto-Native Investment Firms"]=[
("Mubadala Capital","Sovereign-linked investment firm","UAE","Active digital-asset allocator with RWA exposure."),
("Coinbase Asset Management / Superstate","Asset manager","US","Manages tokenized fund products; its USTB fund was taken over by Invesco."),
("KKR","Private-equity firm","US","Tokenized fund exposure distributed via Securitize."),
]
C["Tokenization & Securities Platforms"]=[
("Securitize","Tokenization / issuance platform","US / Global","Leading RWA issuance platform — Hamilton Lane HLSCOPE (first product on TRON), Neuberger Berman HINC, KKR and Apollo funds; ~$1B AUM added in Q2 2026."),
("Figure Technology Solutions (FIGR)","Blockchain-native lending marketplace","US","Agreed to acquire Kiavi ($717M) and partnered with Agora Data to tokenize auto loans via its Hastra platform — first named auto-loan receivables sub-class."),
("Brickken","Tokenization-as-a-service platform","Spain / EU","European RWA tokenization infrastructure provider."),
("Liqi Digital Assets","RWA tokenization platform","Brazil","Latin American tokenization platform."),
("Alphaledger","Municipal-bond tokenization platform","US","Focused on tokenizing US municipal debt."),
("Tradable","Private-credit tokenization platform","US","Tokenization infrastructure for private-credit assets."),
("Dinari","Tokenized-equity issuance / broker-dealer rail","US","Broker-dealer distribution rail for tokenized equities."),
("tZERO","Tokenized-securities ATS","US","Signed Siebert Financial Corp (Aug 20) as a named broker-dealer client for its rail."),
("Datavault AI (DVLT) / Coppercore","Commodity tokenization issuer","US","First named copper-specific commodity tokenization ($100M initial Coppercoin mint, COMEX-linked, in-ground copper resources)."),
("Caliber (Nasdaq: CWD)","CRE alt-asset manager","US","~$2.6B AUM manager; went live (Aug 13) with first tokenized CRE offering (\"PURE Pickleball & Padel\") under a ~$100M program using Chainlink's Automated Compliance Engine."),
("DigiFT","MAS-licensed regulated tokenization exchange","Singapore / Asia-Pacific","Hub connecting BNY, Wellington, SBI, Nashpoint, Franklin Templeton, Arco, BE Trust, Quantum Solutions and GSR — one of Asia's most-connected RWA liquidity/distribution nodes."),
("Nashpoint","RWA access / distribution platform","UK / Europe","Partnered with DigiFT to expand regulated RWA access for European investors."),
("Chuanglian Holdings","Hong Kong-listed / HK-focused company","Hong Kong","Signed an MOU (Aug 5) to build a compliant RWA tokenization and payment-solutions platform in Hong Kong."),
("Arco","Distribution partner","Asia","DigiFT's Asia tokenized-asset distribution partner."),
("BE Trust","Wealth platform","Asia","DigiFT's HNWI-distribution MOU partner."),
("Quantum Solutions","Platform partner","Asia","DigiFT's platform-development MOU partner."),
("OpenAssets","Fixed-income tokenization platform","Brazil","Fixed-income/fund tokenization partner with Itaú Unibanco under Brazil's ANBIMA framework."),
("Stobox","Tokenization platform","Global","Launched AriyaX Capital's AXPT token via its Stobox 4 platform."),
]
C["DeFi Protocols & On-Chain Liquidity"]=[
("Plume Network","RWA-focused blockchain (L1/L2)","US","MOU with Shinhan for a KRW tokenized fund; joined DTCC's Digital Assets Solutions Industry Working Group; holds an SEC-registered transfer-agent affiliate (Kimber Transfer Agency)."),
("Maple Finance","On-chain private-credit protocol","US","DeFi lending protocol focused on institutional private credit."),
("Centrifuge","RWA tokenization / lending protocol","Germany / Global","Integrated Symbiotic's \"Liquid Lane\" for T+0 redemptions on $1.6B of tokenized fund AUM (previously T+1 to T+5)."),
("Goldfinch","Decentralized private-credit protocol","US","On-chain private-credit lending protocol."),
("Morpho","DeFi lending protocol","France","Adding tokenized-RWA collateral to its lending markets."),
("Aave (+ Horizon)","DeFi money market","Global","Leading decentralized lending protocol; Horizon arm powers RWA-collateral lending (incl. Ether.fi integration)."),
("Euler Finance","DeFi lending protocol","UK","Lending protocol expanding into tokenized-RWA collateral."),
("Midas / Fasanara Capital","Tokenized-yield product issuer","UK / EU","Issues tokenized yield products backed by RWA strategies."),
("Ondo Finance","Tokenized-asset protocol","US","Tokenized Treasuries (USDY) and Ondo Stocks (>$1B value, 200,000 holders across 430+ tokenized stocks/ETFs); launched the first custodial tokenized-securities offering in the US with Broadridge."),
("Symbiotic","DeFi collateral / liquidity platform","Global (Paradigm/Pantera/Coinbase Ventures-backed)","\"Liquid Lane\" instant-USDC liquidity facility integrated into Centrifuge, covering Janus Henderson and NYLIM tokenized funds."),
("Orca","Solana DEX / AMM (liquidity provider)","Global — Solana ecosystem","Named on-chain liquidity venue in Shinhan Asset Management's tokenized-won fund pilot — first named Solana DEX tied to a bank-sponsored tokenized fund tracked."),
("Etherfuse","Stablecoin / RWA infrastructure provider","LatAm-founded, expanding to Asia","Named technical partner in the Shinhan pilot, bringing stablecoin and on/off-ramp rails to a fiat-denominated (KRW) tokenized fund."),
("Solana Foundation","Blockchain foundation","Global","Direct named counterparty in Shinhan's four-way tokenization pact — actively courting bank-sponsored RWA issuance in Asia."),
("TRON / TRON DAO","Public blockchain network","Global (383M+ accounts)","Now hosts institutional tokenized private credit (Hamilton Lane's HLSCOPE via Securitize) — first Securitize product issued on TRON."),
("Uniswap","Decentralized exchange","Global","Leading DEX exposed to tokenized-asset trading flows."),
("Hyperliquid","On-chain perpetuals exchange","Global","Perpetuals venue offering tokenized-asset markets."),
]
C["Commodities & Royalties"]=[
("KAIO","Tokenized-commodities platform","Global","Platform for tokenized commodity exposure."),
("ANote Music","Music-royalty tokenization platform","France","Tokenizes music royalty streams for investors."),
("Royalty Exchange","Royalty marketplace","US","Royalty marketplace exploring tokenized distribution."),
("Elemental Royalty Corp","Royalty company","Canada","First royalty company (with EMX) to offer shareholder dividends payable in Tether Gold (XAUT)."),
("EMX Royalty Corporation","Royalty company","Canada","Same Tether Gold dividend program, part of a reported ~$100M Tether investment into the royalty sector."),
("Tether (XAUT / Hadron)","Stablecoin / tokenized-gold issuer","Global","Tokenized-gold issuer (XAUT) and RWA tokenization arm (Hadron); Saudi Arabia real-estate tokenization with named partners First Data and BKN301."),
("Paxos (PAXG)","Tokenized-gold issuer","US","Regulated tokenized-gold issuer."),
("L4VA / Toto Finance","Commodity tokenization (Cardano)","Global","Tokenized silver vault — first commodities entrant beyond gold in this tracker."),
]
C["Exchanges & Brokers"]=[
("Coinbase","Exchange","US / UAE","Secured FSRA permission in Abu Dhabi (ADGM) to build a \"global tokenization hub.\""),
("Kraken","Exchange","US","Tokenized-equity trading plans pending the SEC's forthcoming framework."),
("Robinhood","Brokerage","US","Tokenized-equity trading plans; Robinhood Token wave of tokenized US stocks."),
("Binance","Exchange","Global","bStocks tokenized-equity lineup (10 more names added Aug 22); collateral tie-up with Franklin Templeton's tokenized MMF."),
("Bybit","Exchange","Global","Launched \"RWA Earn,\" bringing institutional RWA investment on-chain to eligible users."),
("Bitget Wallet","Wallet infrastructure","Global","Wallet infrastructure supporting tokenized-asset access."),
("HashKey Exchange","Exchange","Hong Kong","Wealth Management channel launched tokenized access to Apollo's ACRED fund via Securitize — first private-credit tokenized product distributed into Asia."),
("Blockchain.com","Exchange / wallet","Global","Exchange/wallet platform with tokenized-asset access."),
("EDX Markets","Institutional crypto exchange","US","Citadel/Fidelity/Schwab-backed institutional exchange."),
("GRVT","Exchange","Global","Committed to a $100M USDY position, deepening its Ondo Finance tie-up."),
("OTC Markets Group","SEC-regulated ATS operator","US","OTC Link ATS (150+ broker-dealers) partnered with BitGo for tokenized-securities trading."),
("Bullish / Equiniti","Exchange / transfer agent (pending acquisition)","Global","Agreed to acquire Equiniti (global share registrar/transfer agent) for $4.2B, explicitly building \"the global transfer agent for tokenized securities\"; also tokenized its own BLSH shares."),
("Siebert Financial Corp (NASDAQ: SIEB)","Broker-dealer","US","Partnered with tZERO (Aug 20) to give brokerage customers access to tokenized/digital securities."),
("Crypto.com","Exchange","Global","Tokenized-stock derivatives on 1,500 US equities/ETFs."),
("Ether.fi","Exchange / wallet","Global","Tokenized stocks/metals trading plus Aave-powered RWA-collateral lending."),
]
C["Trade Finance & Supply Chain"]=[
("POSCO International","Commodities / trade-finance conglomerate","South Korea","Active in blockchain trade-finance pilots."),
("LG CNS","IT / blockchain infrastructure provider","South Korea","Provides blockchain infrastructure for trade-finance tokenization."),
("TCS / PayPal (PYUSD)","IT services / stablecoin issuer","India / US","Freight-invoice tokenization rail using PayPal's PYUSD stablecoin."),
("DMCC / FutureOne MENA","Free-zone / tokenization initiative","UAE","Dubai commodities free-zone tokenization initiative — no named executed transaction yet."),
("SettleMint","Tokenization middleware provider","Belgium / UAE","In active talks with major UAE banks to tokenize equities, funds, bonds, deposits and gold."),
]
C["Insurance-Linked & Structured Products"]=[
("SurancePlus / HCI Group","Insurance-linked tokenized product","US","Insurance-linked security offered in tokenized form."),
("Infineo","Life-insurance tokenization platform","US","Tokenizes life-insurance-linked assets."),
("Oxbridge Re Holdings","Reinsurer","Cayman Islands / US","Reinsurance company exploring tokenization of risk instruments."),
("Re Protocol","On-chain reinsurance / risk-transfer protocol","Global","DeFi protocol for tokenized reinsurance/risk transfer."),
("Abacus Global Management","Life-settlement / insurance-asset manager","US","Tokenizes life-settlement and insurance-linked assets."),
]
C["Real Estate Specialists"]=[
("SteelWave Digital","CRE tokenization platform","US","Commercial real-estate tokenization specialist."),
("REAL Finance","Real-estate tokenization platform","Global","Partnered with Anchorage Digital (June 2026) for custody/settlement infrastructure across tokenized real estate and other RWA."),
("Factori AD","Real-estate tokenization platform","Global","Real-estate-focused tokenization platform."),
]
C["Maritime & Infrastructure"]=[
("Shipfinex / ADI Chain / ADI Foundation","Maritime-asset tokenization","Global","Vessel tokenization pipeline of ~35 vessels / ~$500M; ADI Foundation secured a $50M strategic investment (Jul 2026) for international expansion."),
("TMC Shipping","Shipowner","Global","Participating shipowner in the Shipfinex tokenization pipeline."),
("AriyaX Capital (AXPT)","Tokenized asset issuer","Global","Launched its AXPT token via the Stobox 4 platform."),
("RWA Global / Golden Dolphin Trading","Infrastructure tokenization","China","$300M deal to tokenize China's EV-charging/clean-energy infrastructure — first infrastructure/EV-charging sub-class tracked."),
]
C["UAE Stablecoin & Settlement Consortium"]=[
("International Holding Company","Investment holding company","UAE","Consortium member developing the DDSC dirham-pegged stablecoin for ADGM tokenization settlement."),
("Sirius International Holding","Investment holding company","UAE","Consortium member developing the DDSC dirham-pegged stablecoin for ADGM tokenization settlement."),
]
# Nombres que solo aparecen en el brief del 9 de agosto
BRIEF_ROWS=[
("Custodians","Apex Group","Global fund administrator","Global","Digital-asset servicing partner on the Goldman Sachs tokenized real estate fund; brings institutional fund administration rails to RWA structures."),
("Custodians","Archax","Digital asset exchange & custodian","UK (FCA-regulated)","Regulated custody/exchange partner on the Goldman Sachs tokenized real estate fund; one of the few FCA-authorized venues for tokenized securities."),
("Global & Regional Banks","Siam Commercial Bank","Regional bank","Thailand","Partner bank for Citi Token Services' 24/7 USD clearing pilot."),
("Exchanges & Brokers","SIX (SIX Digital Exchange)","Exchange / central securities depositary","Switzerland","Digital CSD partner for Citi's tokenized Digital Depositary Receipts."),
("Bank Consortia, Market Infrastructure, Clearing & Ratings","Kaleido","Tokenization platform","Global","Technology partner behind Citi's tokenized Digital Depositary Receipts."),
("Commodities & Royalties","MetaComp Group","Institutional digital-asset services","Asia","Institutional tokenized-gold services."),
("Bank Consortia, Market Infrastructure, Clearing & Ratings","Monetary Authority of Singapore (MAS)","Regulator / central bank","Singapore","Running a 2026 wholesale CBDC pilot for tokenized MAS bills; convenes Project Guardian."),
]
# ---- clasificación al esquema liq_proveedores ----
CAT_TIPO={
 "Global & Regional Banks":("banco",["linea_credito","warehouse","ktft"]),
 "Bank Consortia, Market Infrastructure, Clearing & Ratings":("infraestructura",[]),
 "Asset Managers, Funds & Sovereign Wealth":("gestor_activos",["ktft","emision_b2b","deuda_privada"]),
 "Custodians":("custodio",[]),
 "Market Makers, OTC Desks & Liquidity Providers":("market_maker",["ktft"]),
 "Crypto-Native Investment Firms":("fondo",["ktft","emision_b2b","deuda_privada"]),
 "Tokenization & Securities Platforms":("plataforma_tokenizacion",[]),
 "DeFi Protocols & On-Chain Liquidity":("dao_defi",["ktft"]),
 "Commodities & Royalties":("plataforma_tokenizacion",[]),
 "Exchanges & Brokers":("exchange",["ktft"]),
 "Trade Finance & Supply Chain":("corporativo",["ktft"]),
 "Insurance-Linked & Structured Products":("aseguradora",["deuda_privada"]),
 "Real Estate Specialists":("plataforma_tokenizacion",["emision_b2b"]),
 "Maritime & Infrastructure":("corporativo",["emision_b2b"]),
 "UAE Stablecoin & Settlement Consortium":("corporativo",["ktft"]),
}
TIPO_OVERRIDE={"Khazanah":"soberano","Mubadala Capital":"soberano","State Street":"custodio","Charles Schwab":"banca_inversion",
 "Africa Finance Corporation":"multilateral","LG CNS":"infraestructura","SettleMint":"infraestructura","DMCC / FutureOne MENA":"infraestructura",
 "TCS / PayPal (PYUSD)":"plataforma_tokenizacion","Banque de France":"otro","Deutsche Bundesbank":"otro","Monetary Authority of Singapore (MAS)":"otro",
 "Moody's Ratings":"otro","UK Finance":"otro","Caliber (Nasdaq: CWD)":"gestor_activos","Midas / Fasanara Capital":"gestor_activos",
 "Galaxy Digital":"banca_inversion","Hidden Road":"banca_inversion","Tether (XAUT / Hadron)":"corporativo","Paxos (PAXG)":"corporativo",
 "Elemental Royalty Corp":"corporativo","EMX Royalty Corporation":"corporativo","TMC Shipping":"corporativo","Kaleido":"infraestructura","MetaComp Group":"otro",
 "SIX (SIX Digital Exchange)":"infraestructura","Apex Group":"custodio","Archax":"custodio","Siam Commercial Bank":"banco"}
# Prioridad sugerida para Kabal (LatAm trade finance / private credit): GO = capital desplegable en crédito privado / trade finance / LatAm
GO={"Apollo Global Management","Hamilton Lane","KKR","Maple Finance","Goldfinch","Centrifuge","Franklin Templeton","BlackRock","Itaú Unibanco",
    "Liqi Digital Assets","OpenAssets","Brickken","Securitize","Galaxy Digital","Mubadala Capital","Etherfuse","Komgo","Neuberger Berman",
    "Midas / Fasanara Capital","Tradable","Figure Technology Solutions (FIGR)","Africa Finance Corporation","Ondo Finance","Plume Network","Santander","BNP Paribas"}
def pais(region):
    r=region.split("—")[0].split("(")[0]
    return r.split("/")[0].strip()[:40] or None
rows=[]; seen=set()
for cat,items in C.items():
    tipo,veh=CAT_TIPO[cat]
    for nombre,td,region,tesis in items:
        if nombre in seen: continue
        seen.add(nombre)
        rows.append(dict(nombre=nombre,tipo=TIPO_OVERRIDE.get(nombre,tipo),categoria=cat,tipo_detalle=td,region=region,pais=pais(region),tesis=tesis,
                         vehiculos=veh,calificacion="GO" if nombre in GO else "EXPLORE",fuente="scout_rwa_liquidity",origen_lista=MASTER))
for cat,nombre,td,region,tesis in BRIEF_ROWS:
    if nombre in seen: continue
    seen.add(nombre); tipo,veh=CAT_TIPO[cat]
    rows.append(dict(nombre=nombre,tipo=TIPO_OVERRIDE.get(nombre,tipo),categoria=cat,tipo_detalle=td,region=region,pais=pais(region),tesis=tesis,
                     vehiculos=veh,calificacion="EXPLORE",fuente="scout_rwa_liquidity",origen_lista=BRIEF))
json.dump(rows,open("directorio.json","w"),ensure_ascii=False,indent=1)
def q(s): return "'"+str(s).replace("'","''")+"'" if s is not None else "null"
sql=["insert into public.liq_proveedores (nombre,tipo,pais,vehiculos,calificacion,fuente,categoria,tipo_detalle,region,tesis,origen_lista,notas) values"]
vals=[]
for r in rows:
    vals.append("(%s,%s,%s,'{%s}',%s,%s,%s,%s,%s,%s,%s,%s)"%(q(r["nombre"]),q(r["tipo"]),q(r["pais"]),",".join(r["vehiculos"]),q(r["calificacion"]),q(r["fuente"]),q(r["categoria"]),q(r["tipo_detalle"]),q(r["region"]),q(r["tesis"]),q(r["origen_lista"]),q("Cargado del directorio maestro RWA (23-ago-2026). Verificar independientemente antes del outreach.")))
sql.append(",\n".join(vals))
sql.append("on conflict (nombre) do update set tipo=excluded.tipo, pais=excluded.pais, vehiculos=excluded.vehiculos, categoria=excluded.categoria, tipo_detalle=excluded.tipo_detalle, region=excluded.region, tesis=excluded.tesis, origen_lista=excluded.origen_lista;")
open("directorio_insert.sql","w").write("\n".join(sql))
from collections import Counter
print(len(rows),"instituciones"); print(Counter(r["tipo"] for r in rows).most_common()); print(Counter(r["calificacion"] for r in rows))
