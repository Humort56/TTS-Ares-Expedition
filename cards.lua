----------------------------------------------------------------------------------------------------------------------------
-- 					CH DATA
----------------------------------------------------------------------------------------------------------------------------

local Cards = {
    --  Coporations: Beginner
    InterplanetaryCinematics = {name = 'InterplanetaryCinematics', MC=46, SteelProduction=1, effects={payEvent=-2} },
    Helion = {MC=28, HeatProduction=3, effects={heatAsMC=1} }, -- todo
    Teractor = {MC=51, effects={payEarth=-3}},
    Ecoline = {MC=27, PlantProduction=1, effects={plantForest=-1}},
    -- Corporations: Standard
    Inventrix = {MC=33,Cards=3,effects={conditionPuffer=1}},
    UnitedNationsMarsInitiative = {name='United Nations Mars Initiative',MC=35,effects={}},	-- 6 MC → TR on first time/phase
    SaturnSystems = {name='Saturn Systems',MC=24, TitanProduction=1,effects={onPlayJovian={TR=1}}},
    ThorGate = {MC=45, HeatProduction=1, effects={payPower=-3}},
    PhoboLog = {MC=20, TitanProduction=1, effects={titanValue=1} },
    TharsisRepublic = {name='Tharsis Republic', MC=40, effects={researchDraw=1,researchKeep=1}},
    CrediCor = {MC=48, effects={payTwenty=-4} },
    MiningGuild = {name='Mining Guild', MC=27, SteelProduction=1, effects={onPlaySteelProduction={TR=1}}},
    -- Corporations: Promo
    Arklight = {MC=43, Animals=2, vpAnimals=0.5, onPlayPlant={Animal=1}, onPlayAnimal={Animal=1}}, --todo
    DevTechs = {MC=40, effects={payGreen=-2}, drawChoice=5, manually='Choose a green card from your left hand and discard the other cards.' },
    LaunchStarIncorporated = {name='Launch Star Incorporated', MC=36, effects={payBlue=-3}, revealCards={Color='Blue'}},
    Celestior = {MC=50, action='todo',  }, --todo
    MaiNiProductions = { -- todo
        name='Mai-Ni Productions',
        MC=48,
        onPlayGreen={Cards=1,manually='Discard a card'},
        manually='Play a card from your hand that costs 12 MC or less without paying it.'
    },
    Zetasel = {MC=43, Cards=5, manually='Discard 4 cards', effects={onOcean={MC=2,Plant=2}}},
    -- Cards: Beginner Projects
    AcquiredCompany = {name='Acquired Company', cost=11, production={Cards={Static=1}}},
    AsteroidMiningConsortium = {name='Asteroid Mining Consortium', cost=6, production={Titan={Static=1}}},
    ImportOfAdvancedGHG = {name='Import of Advanced GHG', cost=8, production={Heat={Static=2}}},
    Lichen = {name='Lichen', cost=5, production={Plant={Static=1}}},
    IndustrialFarming = {name='Industrial Farming', cost=19, production={MC={Static=1}, Plant={Static=2}}},
    ArtificialPhotosynthesis = {name='Artificial Photosynthesis', cost=11, production={Plant={Static=1}, Heat={Static=1}}},
    EconomicGrowth = {name='Economic Growth', cost=10, production={MC={Static=3}}},
    SoilWarming = {name='Soil Warming', cost=24, production={Plant={Static=2}}, instant={Temperature=1}},
    SpaceHeaters = {name='Space Heaters', cost=11, production={Heat={Static=2}}, instant={Cards=1}},
    TradingPost = {name='Trading Post', cost=11, production={MC={Static=2}}, instant={Plant=3}},
    Microprocessors = {name='Microprocessors', cost=17, production={Heat={Static=3}}, instant={Cards=2}, manually='Discard a card (from any hand)'},
    CoalImports={name='Coal Imports', cost=13, production={Heat={Static=3}}},
    Sponsors={name='Sponsors', cost=5, production={MC={Static=2}}},
    NewPortfolios={name='New Portfolios', cost=14, production={MC={Static=1},Plant={Static=1},Heat={Static=1}}},
    GreatEscarpmentConsortium = {name='Great Escarpment Consortium', cost=3, production={Steel={Static=1}}},
    NitrophilicMoss = {name='Nitrophilic Moss', cost=14, production={Plant={Static=2}}},
    -- Cards: Kickstarter Promo Projects
    ProcessedMetals = {name='Processed Metals', cost=27, production={Titan={Static=2}}, instant={Cards={Symbol={Power=1}}}, vp=1},
    DiverseHabitats = {name='Diverse Habitats', cost=8, production={MC={Symbol={Animal=1,Plant=1}}}},
    Laboratories = {name='Laboratories', cost=8, production={Cards={Symbol={Science=0.34}}}},
    CommercialImports = {name='Commercial Imports', cost=36, production={Cards={Static=1}, Heat={Static=2}, Plant={Static=2}}},
    ProcessingPlant = {name='Processing Plant', cost=19, production={Steel={Static=2}}, revealCards={Symbol='Building'}, vp=1},
    SelfReplicatingBacteria = {name='Self-Replicating Bacteria', cost=8}, -- action: add microbe or -5 microbe for -25MC on a card
    MatterGenerator = {name='Matter Generator', cost=13, instant={Cards=2}}, -- action: discard a card for 6 mc
    ProgressivePolicies = {name='Progressive Policies', cost=8, action={cost={MC={base=10,reductionCondition={Event=4},reductionVal=5}},profit={Oxygen=1}}},
    FilterFeeders = {
        name='Filter Feeders',
        cost=9,
        tokenType='Animal',
        effects={onMicrobeToken={Token={where='FilterFeeders'}}},
        req={Ocean={value=2,bound='Lower'}},
        vp={token=0.34}
    },
    SyntheticCatastrophe = {name='Synthetic Catastrophe', cost=0}, -- return another red card to the hand
    AssortedEnterprises = {name='Assorted Enterprises', cost=2, state={projectLimit=1}, effects={playGreenDuringConstruction=1,payCardTemp=-2}},
    -- Cards
    CommercialDistrict = {name='Commercial District', cost=25, production={MC={Static=4}}, vp=2},
    IceAsteroid = {name='Ice Asteroid', cost=21, instant={Ocean=2}},
    TundraFarming = {name='Tundra Farming', cost=12, production={MC={Static=2},Plant={Static=1}}, instant={Plant=1}, req={Temperature={range='Yellow',bound='Lower'}}, vp=1},
    ImportedHydrogen = {name='Imported Hydrogen', cost=17, instant={Ocean=1}}, -- gain 3 plants, or 3 microbes, or 2 animals
    IoMiningIndustries = {name='Io Mining Industries', cost=37, production={MC={Static=1},Titan={Static=2}}}, -- 1VP per (Jovian Badge)
    Herbivores = {
        name='Herbivores',
        cost=25,
        tokenType='Animal',
        effects={
            onOcean={Token={where='Herbivores'}},
            onTemperature={Token={where='Herbivores'}},
            onOxygen={Token={where='Herbivores'}}
        },
        req={Ocean={value=5,bound='Lower'}},
        vp={token=0.5}
    },
    PhysicsComplex = {name='PhysicsComplex', cost=5, tokenType='Science', effects={onTemperature={Token={where='PhysicsComplex'}}}, req={Symbol={Science=4}}, vp={token=0.5}},
    NoctisFarming = {name='Noctis Farming', cost=13, production={Plant={Static=1}}, instant={Plant=2}, req={Temperature={range='Red',bound='Lower'}}, vp=1},
    DiversifiedInterests = {name='Diversified Interests', cost=15, production={Plant={Static=1}}, instant={Plant=3,Heat=3}},
    Smelting = {name='Smelting', cost=28, production={Heat={Static=5}}, instant={Cards=2}},
    AdaptationTechnology = {name='Adaptation Technology', cost=12, effects={conditionPuffer=1}, vp=1},
    QuantumExtractor = {name='Quantum Extractor', cost=16, production={Heat={Static=3}}, req={Symbol={Science=3}}, vp=2},
    DeimosDown = {name='Deimos Down', cost=30, instant={Temperature=3,MC=7}},
    NaturalPreserve = {name='Natural Preserve', cost=12, production={MC={Static=2}}, req={Oxygen={range='Red',bound='Lower'}}, vp=1},
    LunarBeam = {name='Lunar Beam', cost=9, production={Heat={Static=4}}, instant={TR=-1}, req={TR=1}},
    HydroElectricEnergy = {name='Hydro-Electric Energy', cost=11, action={cost={MC=1},profit={Heat=2},profitBonus={Heat=1}}},
    Mangrove = {name='Mangrove', cost=12, instant={Forest=1}, req={Temperature={range='White',bound='Lower'}}},
    OptimalAerobraking = {name='Optimal Aerobraking', cost=10, effects={onPlayEvent={Heat=2,Plant=2}}},
    PowerInfrastructure = {name='Power Infrastructure', cost=4}, -- action: convert X heat to X MC
    IceCapMelting = {name='Ice Cap Melting', cost=4, instant={Ocean=1}, req={Temperature={range='White',bound='Lower'}}},
    RecycledDetritus = {name='Recycled Detritus', cost=24, effects={onPlayEvent={Cards=2}}, vp=1},
    LagrangeObservatory = {name='Lagrange Observatory', cost=7, instant={Cards=1}, vp=1},
    FarmersMarket = {name='Farmers Market', cost=12, action={cost={MC=1},profit={Plant=2}}, vp=1},
    FueledGenerators = {name='Fueled Generators', cost=4, production={Heat={Static=2}}, instant={TR=-1}, req={TR=1}, vp=1},
    GHGProducingBacteria = {
        name='GHG Producing Bacteria',
        cost=10,
        tokenType='Microbe',
        action={choice={
            {Token={where='self'}},
            {Action={cost={Token={where='self', value=2}},profit={Temperature=1}}}
        }},
        req={Oxygen={range='Red',bound='Lower'}}
    },
    Decomposers = {
        name='Decomposers',
        cost=7,
        tokenType='Microbe',
        effects={
          onPlayAnimal={choice={
            name='Decomposers',
            choices={
                {Token={where='self'}},
                {Action={cost={Token={where='self', value=1}},profit={Cards=1}}}
            }
          }},
          onPlayPlant={choice={
            name='Decomposers',
            choices={
                {Token={where='self'}},
                {Action={cost={Token={where='self', value=1}},profit={Cards=1}}}
            }
          }},
          onPlayMicrobe={choice={
            name='Decomposers',
            choices={
                {Token={where='self'}},
                {Action={cost={Token={where='self', value=1}},profit={Cards=1}}}
            }
          }},
        },
        req={Oxygen={range='Red',bound='Lower'}},
        vp=1
    },
    ExtendedResources = {name='Extended Resources', cost=10, effects={researchKeep=1}},
    BreathingFilters = {name='Breathing Filters', cost=9, req={Oxygen={range='Yellow',bound='Lower'}}, vp=2},
    AsteroidMining = {name='Asteroid Mining', cost=28, production={Titan={Static=2}}, vp=2},
    ImmigrationShuttles = {name='Immigration Shuttles', cost=20, production={MC={Static=3}}}, -- 1vp per 2 (Earth Badge)
    MassConverter = {name='Mass Converter', cost=20, production={Heat={Static=3},Titan={Static=1}}, req={Symbol={Science=4}}, vp=2},
    BalancedPortfolios = {name='Balanced Portfolios', cost=8, production={MC={Static=3}}, instant={TR=-1}, req={TR=1}, vp=1},
    FarmingCoops = {name='Farming Co-ops', cost=15, instant={Plant=3}}, -- action: discard a card, then gain 3 plants
    InterplanetaryRelations = {name='Interplanetary Relations', cost=35, effects={researchDraw=1,researchKeep=1}}, -- 1vp per 4cards
    BusinessContacts = {name='Business Contacts', cost=5, instant={Cards=4}, manually='Discard 2 cards'},
    GeothermalPower = {name='Geothermal Power', cost=8, production={Heat={Static=2}}},
    ArtificialJungle = {name='Artificial Jungle', cost=5, action={cost={Plant=1},profit={Cards=1}}},
    FoodFactory = {name='Food Factory', cost=9, production={MC={Static=4}}, instant={Plant=-2}, req={Resources={Plant=2}}},
    MediaGroup = {name='Media Group', cost=11, effects={payEvent=-5}},
    InterplanetaryConference = {name='Interplanetary Conference', cost=6, afterEffects={payEarth=-3,onPlayEarth={Cards=1},payJovian=-3,onPlayJovian={Cards=1}}},
    TitaniumMine = {name='Titanium Mine', cost=7, production={Titan={Static=1}}},
    Grass = {name='Grass', cost=9, production={Plant={Static=1}}, instant={Plant=3}, req={Temperature={range='Red',bound='Lower'}}},
    UnderseaVents = {name='Undersea Vents', cost=31, production={Cards={Static=1},Heat={Static=4}}},
    Cartel = {name='Cartel', cost=6, production={MC={Symbol={Earth=1}}}},
    WorkCrews = {name='Work Crews', cost=5, state={projectLimit=1}, effects={payCardTemp=-11}},
    MethaneFromTitan = {name='Methane from Titan', cost=35, production={Plant={Static=2},Heat={Static=2}}, req={Oxygen={range='Red',bound='Lower'}}, vp=2},
    PhobosFalls = {name='Phobos Falls', cost=32, instant={Temperature=1,Ocean=1,Cards=2}, vp=1},
    AutomatedFactories = {
        name='Automated Factories',
        cost=18,
        production={Cards={Static=1}},
        state={projectLimit=1,freeGreenNineLess=1},
        manually='Play another green project with a printed cost of 9MC or less for free'
    },
    EosChasmaNationalPark = {
        name='Eos Chasma National Park',
        cost=16,
        production={MC={Static=2}},
        instant={Plant=3,Token={type='Animal',value=2}},
        req={Temperature={range='Red',bound='Lower'}},
        vp=1},
    CircuitBoardFactory = {name='Circuit Board Factory', cost=14, action={profit={Cards=1}}},
    SmallAnimals = {
        name='Small Animals',
        cost=9,
        tokenType='Animal',
        effects={
            onForest={Token={where='SmallAnimals'}}
        },
        req={Temperature={range='Red',bound='Lower'}},
        vp={token=0.5}
    },
    Trees = {name='Trees', cost=17, production={Plant={Static=3}}, instant={Plant=1}, req={Temperature={range='Yellow',bound='Lower'}}, vp=1},
    AirborneRadiation = {name='Airborne Radiation', cost=15, production={Heat={Static=2}}, instant={Oxygen=1}, req={Oxygen={range='Red',bound='Lower'}}},
    GiantIceAsteroid = {name='Giant Ice Asteroid', cost=36, instant={Temperature=2,Ocean=2}},
    BiomassCombustors = {name='Biomass Combustors', cost=15, production={Heat={Static=5}}, instant={Plant=-2}, req={Resources={Plant=2}}},
    LakeMarineris = {name='Lake Marineris', cost=17, instant={Ocean=2}, req={Temperature={range='Yellow',bound='Lower'}}, vp=1},
    ArcticAlgae = {name='Arctic Algae', cost=19, effects={onOcean={Plant=4}}, req={Temperature={range='Red',bound='Lower'}}, vp=2},
    AtmosphericInsulators = {name='Atmospheric Insulators', cost=10, production={Heat={Symbol={Earth=1}}}},
    SlashAndBurnAgriculture = {name='Slash and Burn Agriculture', cost=8, production={Plant={Static=2}}, vp=-1},
    Plantation = {name='Plantation', cost=22, instant={Forest=2}, req={Symbol={Science=4}}},
    PermafrostExtraction = {name='Permafrost Extraction', cost=8, instant={Ocean=1}, req={Temperature={range='Yellow',bound='Lower'}}},
    BrainstormingSession = {name='Brainstorming Session', cost=8, action={customAction='greenMCrestKeep'}},
    BuildingIndustries = {name='Building Industries', cost=6, production={Steel={Static=2}}, instant={Heat=-4}, req={Resources={Heat=2}}},
    Soletta = {name='Soletta', cost=30, production={Heat={Static=5}}, vp=1},
    AeratedMagma = {name='Aerated Magma', cost=18, production={Cards={Static=1},Heat={Static=2}}, req={Oxygen={range='Red',bound='Lower'}}},
    TowingAComet = {name='Towing a Comet', cost=22, instant={Oxygen=1, Ocean=1, Plant=2}},
    TechnologyDemonstration = {name='Technology Demonstration', cost=17, instant={Ocean=1,Cards=2}},
    Mine = {name='Mine', cost=10, production={Steel={Static=2}}},
    GreatDam = {name='Great Dam', cost=12, production={Heat={Static=2}}, req={Ocean={value=2,bound='Lower'}}, vp=1},
    Heather = {name='Heather', cost=14, production={Plant={Static=1}}, instant={Plant=1}, vp=1},
    WavePower = {name='Wave Power', cost=9, production={Heat={Static=3}}, req={Ocean={value=3,bound='Lower'}}},
    CEOsFavoriteProject = {
        name="CEO's Favorite Project",
        cost=3,
        instant={Token={type={'Animal','Microbe','Science'},value=2}}
    },
    EcologicalZone = {
        name='Ecological Zone',
        cost=11,
        tokenType='Animal',
        effects={
            onPlayAnimal={Token={where='EcologicalZone'}},
            onPlayPlant={Token={where='EcologicalZone'}}
        },
        vp={token=0.5}
    },
    AdaptedLichen = {name='Adapted Lichen', cost=6, production={Plant={Static=1}}},
    Crater = {name='Crater', cost=7, instant={Ocean=1}, req={Symbol={Event=3}}},
    ResearchOutpost = {name='ResearchOutpost', cost=6, effects={payCard=-1}},
    StripMine = {name='Strip Mine', cost=12, production={Steel={Static=2},Titan={Static=1}}, instant={TR=-1}, req={TR=1}},
    InterstellarColonyShip = {name='Interstellar Colony Ship', cost=20, req={Symbol={Science=4}}, vp=4},
    ColonizerTrainingCamp = {name='Colonizer Training Camp', cost=10, req={Oxygen={range='Red',bound='Upper'}}, vp=2},
    RedraftedContracts = {name='Redrafted Contracts', cost=4}, -- action: discard 1-3, draw that many
    ImportedNitrogen = {
        name='Imported Nitrogen',
        cost=20,
        instant={
            TR=1,
            Plant=4,
            Token={
                {type='Microbe',value=3},
                {type='Animal',value=2}
            }
        }},
    WaterImportFromEuropa = {name='Water Import from Europa', cost=22,  action={cost={MC={base=12,reductionRes='Titan',reductionVal=1}}, profit={Ocean=1}}}, -- 1vp per (Jovian)
    AssemblyLines = {name='Assembly Lines', cost=13, effects={gainForCustomAction=1}},
    SubterraneanReservoir = {name='Subterranean Reservoir', cost=10, instant={Ocean=1}},
    ImportedGHG = {name='Imported GHG', cost=8, production={Heat={Static=1}}, instant={Heat=5}},
    TerraformingGanymede = {name='Terraforming Ganymede', cost=28, instant={TR={Symbol={Jovian=1}}}, vp=2},
    SolarPower = {name='Solar Power', cost=10, production={Heat={Static=1}}, vp=1},
    Solarpunk = {name='Solarpunk', cost=15,  action={cost={MC={base=15,reductionRes='Titan',reductionVal=2}}, profit={Forest=1}}, vp=1},
    PowerPlant = {name='Power Plant', cost=3, production={Heat={Static=1}}},
    EnergyStorage = {name='Energy Storage', cost=18, production={Cards={Static=2}}, req={TR=7}},
    CompostingFactory = {name='Composting Factory', cost=13, effects={cardValue=1}, vp=1},
    ExtremeColdFungus = {
        name='Extreme-Cold Fungus',
        cost=10,
        action={choice={
            {Token={type='Microbe'}},
            {Action={profit={Plant=1}}}
        }},
        req={Temperature={range='Purple',bound='Upper'}}
    },
    DeepWellHeating = {name='Deep Well Heating', cost=14, production={Heat={Static=1}}, instant={Temperature=1}},
    AssetLiquidation = {
        name='Asset Liquidation',
        cost=0,
        state={projectLimit=1},
        action={cost={TR=1},profit={Cards=3}}
    },
    UnitedPlanetaryAlliance = {name='United Planetary Alliance', cost=11, effects={researchDraw=1,researchKeep=1}},
    GeneRepair = {name='Gene Repair', cost=15, production={MC={Static=2}}, vp=2},
    AtmosphereFiltering = {name='Atmosphere Filtering', cost=6, instant={Oxygen=1}, req={Symbol={Science=2}}},
    VentureCapitalism = {name='Venture Capitalism', cost=11, production={MC={Symbol={Event=1}}}},
    MirandaResort = {name='Miranda Resort', cost=15, production={MC={Symbol={Earth=1}}}, vp=1},
    SymbioticFungus = {
        name='Symbiotic Fungus',
        cost=3,
        action={profit={Token='Microbe'}},
        req={Temperature={range='Red',bound='Lower'}}
    },
    Livestock = {
        name='Livestock',
        cost=15,
        tokenType='Animal',
        effects={
            onTemperature={Token={where='Livestock'}}
        },
        req={Oxygen={range='Yellow',bound='Lower'}},
        vp={token=1}
    },
    PowerSupplyConsortium = {name='Power Supply Consortium', cost=12, production={MC={Static=2},Heat={Static=1}}},
    TollStation = {
        name='Toll Station',
        cost=16,
        production={MC={Static=3}},
        state={projectLimit=1,freeGreenNineLess=1},
        manually='Play another green project with a printed cost of 9MC or less for free'
    },
    LocalHeatTrapping = {
        name='Local Heat Trapping',
        cost=0,
        instant={Plant=4,Heat=-3,Token={type={'Animal','Microbe'},value=2}},
        req={Resources={Heat=3}}
    },
    SpecialDesign = {name='Special Design', cost=3, effects={conditionPufferTemp=1}, state={projectLimit=1}},
    ProtectedValley = {name='Protected Valley', cost=22, production={MC={Static=2}}, instant={Forest=1}},
    AdvancedEcosystems = {name='Advanced Ecosystems', cost=10, req={Symbol={Animal=1,Microbe=1,Plant=1}}, vp=3},
    ConvoyFromEuropa = {name='Convoy from Europa', cost=14, instant={Cards=1,Ocean=1}},
    DustyQuarry = {name='Dusty Quarry', cost=2, production={Steel={Static=1}}, req={Ocean={value=3,bound='Upper'}}},
    ThinkTank = {
        name='Think Tank',
        cost=13,
        action={cost={MC=2},profit={Cards=1}},
        vp={Cards={Blue=0.34}}
    },
    InvestmentLoan = {name='Investment Loan', cost=1, instant={MC=10,TR=-1}, req={TR=1}, vp=1},
    ConservedBiome = {name='Conserved Biome', cost=25, action={profit={Token={'Animal','Microbe'}}}, vp={forest=0.5}},
    RegolithEaters = {
        name='Regolith Eaters',
        cost=10,
        tokenType='Microbe',
        action={choice={
            {Token={where='self'}},
            {Action={cost={Token={where='self', value=2},profit={Oxygen=1}}}}
        }},
        req={Temperature={range='Red',bound='Lower'}}
    },
    Steelworks = {name='Steelworks', cost=15, action={cost={Heat=6},profit={MC=2,Oxygen=1}}, vp=1},
    BiothermalPower = {name='Biothermal Power', cost=18, production={Heat={Static=1}}, instant={Forest=1}},
    Fish = {name='Fish', cost=11, tokenType='Animal', effects={onOcean={Token={where='Fish'}}}, req={Temperature={range='Red',bound='Lower'}}, vp={token=1}},
    StandardTechnology = {name='Standard Technology', cost=15, effects={payStandardAction=-4}, vp=1},
    Algae = {name='Algae', cost=9, production={Plant={Static=2}}, req={Ocean={value=5,bound='Lower'}}},
    UndergroundCity = {name='Underground City', cost=7, production={MC={Static=1},Steel={Static=1}}},
    SatelliteFarms = {name='Satellite Farms', cost=17, production={Heat={Symbol={Space=1}}}},
    AquiferPumping = {name='Aquifer Pumping', cost=14, action={cost={MC={base=10,reductionRes='Steel',reductionVal=2}}, profit={Ocean=1}}},
    EnergySubsidies = {name='Energy Subsidies', cost=5, effects={payPower=-2,onPlayPower={Cards=1}}},
    IndustrialCenter = {name='Industrial Center', cost=15, production={MC={Static=3},Steel={Static=1}}},
    OlympusConference = {name='Olympus Conference', cost=15, effects={onPlayScience={Cards=1}}, vp=1},
    InventionContest = {name='Invention Contest', cost=1, instant={Cards=3}, manually='Keep one card from your left hand'},
    AntiGravityTechnology = {name='Anti-Gravity Technology', cost=18, effects={onPlayCard={Heat=2,Plant=2}}, req={Symbol={Science=5}}, vp=3},
    DevelopedInfrastructure = {name='Developed Infrastructure', cost=12, action={cost={MC={base=10,reductionCondition={Blue=5},reductionVal=5}},profit={Temperature=1}}, vp=1},
    MedicalLab = {name='Medical Lab', cost=15, production={MC={Symbol={Building=0.5}}}, vp=1},
    DecomposingFungus = {name='Decomposing Fungus', cost=10}, --instant: 2microbe, action: remove 1 animal or microbe for 3 plant
    IndustrialMicrobes = {name='Industrial Microbes', cost=9, production={Heat={Static=1},Steel={Static=1}}},
    Monocultures = {name='Monocultures', cost=6, production={Plant={Static=2}}, instant={TR=-1}, req={TR=1}},
    LargeConvoy = {name='Large Convoy', cost=36, instant={Ocean=1,Cards=2}, manually='Gain 5 plants or 3 animals', vp=2},
    Interns = {name='Interns', cost=3, effects={researchDraw=2}},
    VestaShipyard = {name='Vesta Shipyard', cost=16, production={Titan={Static=1}}, vp=1},
    Tardigrades = {
        name='Tardigrades',
        cost=6,
        tokenType='Microbe',
        action={profit={Token={where='self'}}},
        vp={token=0.34}
    },
    NuclearPlants = {name='Nuclear Plants', cost=10, production={MC={Static=1},Heat={Static=3}}, vp=-1},
    PowerGrid = {name='Power Grid', cost=8, production={MC={Symbol={Power=1}}}},
    Windmills = {name='Windmills', cost=10, production={Heat={Symbol={Power=1}}}, vp=1},
    TropicalResort = {name='Tropical Resort', cost=19, production={MC={Static=4}}, instant={Heat=-5}, req={Resources={Heat=5}}, vp=2},
    Astrofarm = {
        name='Astrofarm',
        cost=21,
        production={Plant={Static=1},Heat={Static=3}},
        instant={Token={type='Microbe',value=2}}
    },
    TrappedHeat = {name='Trapped Heat', cost=20, production={Heat={Static=2}}, instant={Ocean=1}, req={Temperature={range='Red',bound='Lower'}}},
    ReleaseOfInertGases = {name='Release of Inert Gases', cost=16, instant={TR=2}},
    LightningHarvest = {name='Lightning Harvest', cost=13, production={MC={Symbol={Science=1}}}, vp=1},
    BribedCommittee = {name='Bribed Committee', cost=5, instant={TR=2}, vp=-2},
    Farming = {name='Farming', cost=20, production={MC={Static=2},Plant={Static=2}}, instant={Plant=2}, req={Temperature={range='White',bound='Lower'}}, vp=2},
    AnaerobicMicroorganisms = {
        name='Anaerobic Microorganisms',
        cost=10,
        tokenType='Microbe',
        effects={
            onPlayPlant={Token={where='AnaerobicMicroorganisms'}},
            onPlayMicrobe={Token={where='AnaerobicMicroorganisms'}},
            onPlayAnimal={Token={where='AnaerobicMicroorganisms'}}
        },
        onPlayAction={
            where='AnaerobicMicroorganisms',
            cost={Token={where='self',value=2}},
            profit={effects={payCardTemp=-10}}
        }
    },
    SpaceStation = {name='Space Station', cost=14, production={Titan={Static=1}}, vp=1},
    FuelFactory = {name='Fuel Factory', cost=9, production={MC={Static=1},Titan={Static=1}}, instant={Heat=-3}, req={Resources={Heat=3}}},
    Blueprints = {name='Blueprints', cost=17, production={Cards={Static=1},MC={Static=2}}},
    KelpFarming = {name='Kelp Farming', cost=17, production={MC={Static=2},Plant={Static=3}}, instant={Plant=2}, req={Ocean={value=6,bound='Lower'}}, vp=1},
    TectonicStressPower = {name='Tectonic Stress Power', cost=20, production={Heat={Static=3}}, vp=1},
    SurfaceMines = {name='Surface Mines', cost=13, production={Steel={Static=1},Titan={Static=1}}},
    AdvancedAlloys = {name='Advanced Alloys', cost=9, effects={steelValue=1,titanValue=1}},
    Zeppelins = {name='Zeppelins', cost=10, production={MC={Forest=1}}, req={Oxygen={range='Red',bound='Lower'}}, vp=1},
    MatterManufacturing = {name='Matter Manufacturing', cost=9, action={cost={MC=1},profit={Cards=1}}},
    ViralEnhancers = {
        name='Viral Enhancers',
        cost=8,
        effects={
            onPlayAnimal={choice={
                name='ViralEnhancers',
                choices={
                    {Token={type={'Microbe','Animal'}}},
                    {Action={where='self',profit={Plant=1}}}
                }
            }},
            onPlayMicrobe={choice={
                name='ViralEnhancers',
                choices={
                    {Token={type={'Microbe','Animal'}}},
                    {Action={where='self',profit={Plant=1}}}
                }
            }},
            onPlayPlant={choice={
                name='ViralEnhancers',
                choices={
                    {Token={type={'Microbe','Animal'}}},
                    {Action={where='self',profit={Plant=1}}}
                }
            }}
        }
    },
    AICentral = {name='AI Central', cost=22, action={profit={Cards=2}}, req={Symbol={Science=5}}, vp=2},
    Worms = {name='Worms', cost=11, production={Plant={Symbol={Microbe=1}}}, req={Oxygen={range='Red',bound='Lower'}}},
    Greenhouses = {name='Greenhouses', cost=11, req={Temperature={range='Yellow',bound='Lower'}}}, --action: 1-4Heat => 1-4Plant
    Satellites = {name='Satellites', cost=14, production={MC={Symbol={Space=1}}}},
    Ironworks = {name='Ironworks', cost=12, action={cost={Heat=4},profit={Oxygen=1}}},
    SolarTrapping = {name='Solar Trapping', cost=10, production={Heat={Static=1}}, instant={Cards=1,Heat=3}},
    WoodBurningStoves = {name='Wood Burning Stoves', cost=13, instant={Plant=4}, action={cost={Plant={base=4,reductionAction=1}},profit={Temperature=1}}},
    LowAtmoShields = {name='Low-Atmo Shields', cost=9, production={MC={Static=1},Heat={Static=2}}, req={Oxygen={range='Red',bound='Lower'}}},
    Moss = {name='Moss', cost=3, production={Plant={Static=1}}, instant={Plant=-1}, req={Ocean={value=3,bound='Lower'},Resources={Plant=2}}},
    RadSuits = {name='Rad Suits', cost=4, production={MC={Static=2}}, req={Ocean={value=2,bound='Lower'}}},
    MicroMills = {name='Micro-Mills', cost=9, production={Heat={Static=1},Steel={Static=1}}},
    EarthCatapult = {name='Earth Catapult', cost=24, effects={payCard=-2}, vp=2},
    Birds = {
        name='Birds',
        cost=15,
        action={
            profit={Token={where='Birds'}}
        },
        req={Oxygen={range='White',bound='Lower'}},
        vp={token=1}
    },
    ArtificialLake = {name='Artificial Lake', cost=13, instant={Ocean=1}, req={Oxygen={range='Yellow',bound='Lower'}}, vp=1},
    NitriteReducingBacteria = {
        name='Nitrite Reducing Bacteria',
        cost=11,
        tokenType='Microbe',
        action={choice={
            {Token={where='self'}},
            {Action={cost={Token={where='self', value=3}},profit={Ocean=1}}}
        }},
        instant={Token={where='self',value=3}}
    },
    AdvancedScreeningTechnology = {name='Advanced Screening Technology', cost=6}, --action: reveal 3 cards, keep one card with (Plant/Science)
    DesignedMicroorganisms = {name='Designed Microorganisms', cost=15, production={Plant={Static=2}}, req={Temperature={range='Red',bound='Upper'}}},
    Insects = {name='Insects', cost=10, production={Plant={Symbol={Plant=1}}}},
    BeamFromAThoriumAsteroid = {name='Beam from a Thorium Asteroid', cost=23, production={Plant={Static=1},Heat={Static=3}}, req={Symbol={Jovian=1}}, vp=1},
    Bushes = {name='Bushes', cost=13, production={Plant={Static=2}},instant={Plant=2}, req={Temperature={range='Red',bound='Lower'}}},
    RestructuredResources = {
        name='Restructured Resources',
        cost=7,
        onPlayAction={
            where='RestructuredResources',
            cost={Plant=1},
            profit={effects={payCardTemp=-5}}
        }
    },
    GanymedeShipyard = {name='Ganymede Shipyard', cost=17, production={Titan={Static=2}}},
    Research = {name='Research', cost=5, instant={Cards=2}},
    GiantSpaceMirror = {name='Giant Space Mirror', cost=13, production={Heat={Static=3}}},
    VolcanicPools = {
        name='Volcanic Pools',
        cost=17,
        action={
            cost={MC={base=12,reductionSymbol='Power',reductionVal=1}},
            profit={Ocean=1}
        },
        vp=1
    },
    CaretakerContract = {name='Caretaker Contract', cost=18, action={cost={Heat=8},profit={TR=1}}, vp=2},
    DevelopmentCenter = {name='Development Center', cost=7, action={cost={Heat=2},profit={Cards=1}}},
    MoholeArea = {name='Mohole Area', cost=18, production={Heat={Static=4}}},
    Archaebacteria = {name='Archaebacteria', cost=5, production={Plant={Static=1}}, req={Temperature={range='Purple',bound='Upper'}}},
    MarsUniversity = {name='Mars University', cost=10, vp=1}, --effect: (Science): discard a card => (Plant)2 cards, else 1 cards
    CallistoPenalMines = {name='Callisto Penal Mines', cost=20, production={Cards={Static=1}}, vp=1},
    NitrogenRichAsteroid = {name='Nitrogen-Rich Asteroid', cost=30, instant={TR=2,Temperature=1}, manually='If you have more than 3 symbols Plant, gain 4 plants, else gain 2 plants'}, -- 2 plants, 3+(Plant) 4 Plant
    FusionPower = {name='Fusion Power', cost=7, production={Cards={Static=1}}, req={Symbol={Power=2}}},
    Comet = {name='Comet', cost=25, instant={Temperature=1,Ocean=1}},
    CommunityGardens = {name='Community Gardens', cost=20, action={profit={MC=2},profitBonus={Plant=1}}},
    LavaFlows = {name='Lava Flows', cost=17, instant={Temperature=2}},
}

return Cards