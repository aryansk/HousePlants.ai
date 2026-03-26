import json

# DATABASE OF GENERA AND SPECIES/CULTIVARS
# Combined to create unique entries.
plant_database = {
    "Philodendron": [
        "Hederaceum (Heartleaf)", "Brasil", "Micans", "Pink Princess", "White Knight", "White Princess", 
        "White Wizard", "Prince of Orange", "Rojo Congo", "Birkin", "Moonlight", "Gloriosum", "Melanochrysum", 
        "Verrucosum", "Squamiferum", "Florida Ghost", "Florida Beauty", "Billietiae", "Atabapoense", "Brandtianum",
        "Burle Marx", "Silver Sword (Hastatum)", "Tortum", "Pedatum", "Bipennifolium", "Giganteum", "Spiritus Sancti",
        "Patriciae", "Bernardopazii", "Campaii", "69686", "Joepii", "Paraiso Verde", "Ring of Fire", "Imperial Green",
        "Imperial Red", "Xanadu", "Bipinnatifidum (Selloum)", "Goeldii", "Mayoi", "Grazielae", "Rugosum", "Plowmanii",
        "Mamei", "Pastazanum", "Dean McDowell", "El Choco Red", "Luxurians", "Serpens", "Tripartitum"
    ],
    "Monstera": [
        "Deliciosa", "Deliciosa Albo Variegata", "Deliciosa Thai Constellation", "Deliciosa Aurea", "Adansonii (Swiss Cheese)",
        "Adansonii Laniata", "Adansonii Mint", "Obliqua Peru", "Siltepecana", "Dubia", "Standleyana", "Standleyana Albo",
        "Pinnatipartita", "Karstenianum (Peru)", "Acacoyaguensis", "Subpinnata", "Spruceana", "Lechleriana", "Burle Marx Flame",
        "Esqueleto", "Acuminata"
    ],
    "Anthurium": [
        "Andraeanum (Flamingo Flower)", "Clarinervium", "Crystallinum", "Warocqueanum (Queen)", "Veitchii (King)",
        "Forgetii", "Magnificum", "Regale", "Luxurians", "Vittarifolium", "Bakeri", "Gracile", "Superbum",
        "Hookeri", "Plowmanii", "Faustomirandae", "Pedatoradiatum", "Podophyllum", "Clavigerum", "Polyschistum",
        "Coriaceum", "Radicans", "Dressleri", "Kunayalense", "Villenaorum", "Lineolatum", "Splendidum"
    ],
    "Alocasia": [
        "Amazonica (Polly)", "Zebrina", "Baginda (Dragon Scale)", "Cuprea (Red Secret)", "Macrorrhizos (Giant Taro)",
        "Odora", "Micholitziana (Frydek)", "Frydek Variegata", "Reginula (Black Velvet)", "Maharani (Grey Dragon)",
        "Melo", "Silver Dragon", "Nebula", "Bisma", "Longiloba", "Sarian", "Lauterbachiana", "Stingray", "Jacklyn",
        "Portodora", "Wentii", "Cucullata", "Azlanii", "Sinuata", "Scalprum", "Heterophylla"
    ],
    "Syngonium": [
        "Podophyllum (Arrowhead)", "White Butterfly", "Neon Robusta", "Pink Splash", "Pink Spot", "Mojito",
        "Albo Variegatum", "Aurea Variegatum", "Three Kings", "Confetti", "Milk Confetti", "Rayii", "Wendlandii",
        "Erythrophyllum (Llano Carti Carti)", "Chiapense", "Auritum", "Macrophyllum", "Starlite", "Pixie", "Glo Go"
    ],
    "Epipremnum (Pothos)": [
        "Aureum (Golden)", "Marble Queen", "Neon", "Jade", "Manjula", "Pearls and Jade", "N'Joy", "Global Green",
        "Cebu Blue", "Baltic Blue", "Pinnatum", "Pinnatum Albo", "Skeleton Key"
    ],
    "Scindapsus": [
        "Pictus Argyraeus", "Pictus Exotica", "Pictus Silvery Ann", "Treubii Moonlight", "Treubii Dark Form",
        "Jade Satin", "Officinalis", "Mayari"
    ],
    "Hoya": [
        "Carnosa", "Carnosa Compacta (Hindu Rope)", "Carnosa Tricolor", "Kerrii (Sweetheart)", "Kerrii Variegata",
        "Pubicalyx", "Pubicalyx Splash", "Australis", "Australis Lisa", "Obovata", "Lacunosa", "Sunrise", "Mathilde",
        "Serpens", "Linearis", "Retusa", "Polyneura (Fishtail)", "Multiflora (Shooting Star)", "Bella", "Wayetii",
        "Kentiana", "Shepherdii", "Crimson Queen", "Crimson Princess", "Memoria", "Fungii", "Callistophylla",
        "Finlaysonii", "Undulata", "Caudata", "Imbricata", "Curtisii", "Krohniana", "Krohniana Silver", "Sigillatis",
        "Elliptica", "Globulosa", "Villosa", "Spartioides", "Imperialis", "Macrophylla", "Latifolia"
    ],
    "Peperomia": [
        "Obtusifolia (Baby Rubber)", "Obtusifolia Variegata", "Argyreia (Watermelon)", "Caperata (Ripple)",
        "Caperata Rosso", "Caperata Frost", "Caperata Quito", "Polybotrya (Raindrop)", "Prostrata (String of Turtles)",
        "Hope", "Tetragona (Parallel)", "Perciliata", "Rotundifolia", "Verticillata", "Graveolens", "Clusiifolia (Jelly)",
        "Incana", "Serpens", "Scandens", "Pixie Lime"
    ],
    "Calathea/Goeppertia": [
        "Orbifolia", "Ornata (Pinstripe)", "Makoyana (Peacock)", "Lancifolia (Rattlesnake)", "Roseopicta",
        "Roseopicta Dottie", "Roseopicta Medallion", "Zebra (Zebrina)", "Warscewiczii", "Rufibarba (Velvet)",
        "Musaica (Network)", "Beauty Star", "Freddie", "Leopardina", "White Fusion", "Yellow Fusion", "Stella", "Misto"
    ],
    "Maranta": [
        "Leuconeura (Red Prayer Plant)", "Leuconeura Kerchoveana (Green)", "Leuconeura Lemon Lime", 
        "Leuconeura Silver Band", "Arundinacea"
    ],
    "Sansevieria (Dracaena)": [
        "Trifasciata (Laurentii)", "Zeylanica", "Cylindrica", "Masoniana (Whale Fin)", "Moonshine", "Bantel's Sensation",
        "Fernwood", "Starfish", "Samurai", "Pinguicula", "Kirkii", "Coppertone", "Cleopatra", "Parva", "Francisii", 
        "Ehrenbergii"
    ],
    "Aglaonema": [
        "Modestum (Chinese Evergreen)", "Silver Bay", "Maria", "Siam Aurora", "Red Valentine", "Pink Splash", 
        "Chocolate", "Prestige", "White Anya", "Cutlass", "Emerald Beauty", "Sparkling Sarah", "Lady Valentine",
        "Pictum Tricolor", "Rotundum"
    ],
    "Ficus": [
        "Lyrata (Fiddle Leaf Fig)", "Elastica (Rubber Plant)", "Elastica Tineke", "Elastica Ruby", "Elastica Burgundy",
        "Benjamina (Weeping Fig)", "Benghalensis (Audrey)", "Alii", "Pumila (Creeping Fig)", "Pumila Quercifolia",
        "Triangularis", "Triangularis Variegata", "Microcarpa (Ginseng)", "Altissima", "Umbellata"
    ],
    "Dracaena": [
        "Marginata (Dragon Tree)", "Marginata Tricolor", "Fragrans (Corn Plant)", "Fragrans Lemon Lime", "Warneckii",
        "Janet Craig", "Compacta", "Sanderiana (Lucky Bamboo)", "Reflexa (Song of India)", "Surculosa (Gold Dust)"
    ],
    "Succulents": [
        "Aloe Vera", "Aloe Aristata", "Aloe Juvenna", "Haworthia Fasciata (Zebra)", "Haworthia Cooperi",
        "Haworthia Cymbiformis", "Echeveria Elegans", "Echeveria Lola", "Echeveria Black Prince", "Echeveria Perle von Nurnberg",
        "Sedum Morganianum (Burro's Tail)", "Sedum Rubrotinctum (Jelly Bean)", "Crassula Ovata (Jade)", "Crassula Ovata Gollum",
        "Kalanchoe Tomentosa (Panda Plant)", "Kalanchoe Thyrsiflora (Paddle Plant)", "Senecio Rowleyanus (String of Pearls)",
        "Senecio Radicans (String of Bananas)", "Senecio Peregrinus (String of Dolphins)", "Ceropegia Woodii (String of Hearts)",
        "Cotyledon Tomentosa (Bear's Paw)", "Graptopetalum Paraguayense", "Sempervivum Tectorum (Hens and Chicks)",
        "Lithops (Living Stones)", "Faucaria Tigrina (Tiger Jaws)", "Gasteria Batesiana"
    ],
    "Cacti": [
        "Schlumbergera (Christmas Cactus)", "Rhipsalis Baccifera (Mistletoe Cactus)", "Epiphyllum Oxypetalum (Queen of Night)",
        "Opuntia Microdasys (Bunny Ear)", "Opuntia Ficus-Indica", "Echinocactus Grusonii (Golden Barrel)",
        "Astrophytum Asterias", "Mammillaria Elongata", "Mammillaria Plumosa", "Gymnocalycium Mihanovichii (Moon Cactus)",
        "Cereus Peruvianus", "Myrtillocactus Geometrizans", "Cephalocereus Senilis (Old Man Cactus)"
    ],
    "Ferns": [
        "Nephrolepis Exaltata (Boston)", "Nephrolepis Cordifolia (Lemon Button)", "Adiantum Raddianum (Maidenhair)",
        "Asplenium Nidus (Bird's Nest)", "Platycerium Bifurcatum (Staghorn)", "Davallia Fejeensis (Rabbit's Foot)",
        "Phlebodium Aureum (Blue Star)", "Pteris Cretica (Silver Ribbon)", "Cyrtomium Falcatum (Holly Fern)",
        "Asparagus Densiflorus (Asparagus Fern)", "Humata Tyermannii (White Rabbit's Foot)"
    ],
    "Palms": [
        "Chamaedorea Elegans (Parlor)", "Dypsis Lutescens (Areca)", "Rhapis Excelsa (Lady)", "Howea Forsteriana (Kentia)",
        "Phoenix Roebelenii (Pygmy Date)", "Ravenea Rivularis (Majesty)", "Caryota Mitis (Fishtail)", "Beaucarnea Recurvata (Ponytail)"
    ],
    "Begonia": [
        "Maculata (Polka Dot)", "Rex", "Masoniana (Iron Cross)", "Ferox", "Breverimosa", "Amphioxus", "Dregei",
        "Semperflorens (Wax)", "Tuberous"
    ],
    "Tradescantia": [
        "Zebrina", "Nanouk", "Pallida (Purple Heart)", "Spathacea (Moses in the Cradle)", "Fluminensis", "Sillamontana"
    ],
    "Herbs (Indoor/Outdoor)": [
        "Basil (Genovese)", "Basil (Thai)", "Rosemary", "Thyme", "Mint (Peppermint)", "Mint (Spearmint)",
        "Oregano", "Parsley (Curly)", "Parsley (Flat Leaf)", "Cilantro", "Sage", "Dill", "Chives", "Lavender (English)",
        "Lavender (French)", "Lemon Balm", "Tarragon", "Marjoram"
    ],
    "Outdoor Flowers (Container)": [
        "Petunia", "Geranium (Pelargonium)", "Impatiens", "Begonia (Wax)", "Marigold (Tagetes)", "Pansy", "Viola",
        "Snapdragon", "Zinnia", "Cosmos", "Fuchsia", "Lantana", "Verbena", "Calibrachoa (Million Bells)", "Lobelia",
        "Alyssum", "Coleus", "Heliotrope", "Dahlia (Dwarf)", "Chrysanthemum", "Cyclamen", "Primula"
    ],
    "Trees/Shrubs (Outdoor Container)": [
        "Japanese Maple (Acer palmatum)", "Boxwood (Buxus)", "Hydrangea Macrophylla", "Azalea", "Camellia Japonica",
        "Rose (Miniature)", "Hibiscus (Tropical)", "Bougainvillea", "Gardenia Jasminoides", "Olive Tree (Olea europaea)",
        "Lemon Tree (Meyer)", "Lime Tree (Key)", "Kumquat", "Fig (Edible)", "Dwarf Alberta Spruce"
    ]
}

# CARE TEMPLATES BASED ON CATEGORY
care_guides = {
    "Philodendron": {"cat": "Indoor", "light": "Bright Indirect", "water": "Moderate", "diff": "Easy", "tox": True},
    "Monstera": {"cat": "Indoor", "light": "Bright Indirect", "water": "Moderate", "diff": "Easy/Medium", "tox": True},
    "Anthurium": {"cat": "Indoor", "light": "Bright Indirect", "water": "High Humidity", "diff": "Medium/Hard", "tox": True},
    "Alocasia": {"cat": "Indoor", "light": "Bright Indirect", "water": "Moist/Humid", "diff": "Medium", "tox": True},
    "Syngonium": {"cat": "Indoor", "light": "Low to Bright", "water": "Moderate", "diff": "Easy", "tox": True},
    "Epipremnum (Pothos)": {"cat": "Indoor", "light": "Low to Bright", "water": "Low", "diff": "Easy", "tox": True},
    "Scindapsus": {"cat": "Indoor", "light": "Medium Indirect", "water": "Low", "diff": "Easy", "tox": True},
    "Hoya": {"cat": "Indoor", "light": "Bright Indirect", "water": "Low (Dry out)", "diff": "Easy", "tox": False},
    "Peperomia": {"cat": "Indoor", "light": "Medium Indirect", "water": "Low", "diff": "Easy", "tox": False},
    "Calathea/Goeppertia": {"cat": "Indoor", "light": "Low/Medium", "water": "High (Distilled)", "diff": "Hard", "tox": False},
    "Maranta": {"cat": "Indoor", "light": "Low/Medium", "water": "High", "diff": "Medium", "tox": False},
    "Sansevieria (Dracaena)": {"cat": "Indoor", "light": "Any", "water": "Very Low", "diff": "Easy", "tox": True},
    "Aglaonema": {"cat": "Indoor", "light": "Low to Bright", "water": "Moderate", "diff": "Easy", "tox": True},
    "Ficus": {"cat": "Indoor", "light": "Bright Indirect", "water": "Moderate", "diff": "Medium", "tox": True},
    "Dracaena": {"cat": "Indoor", "light": "Low to Bright", "water": "Low", "diff": "Easy", "tox": True},
    "Succulents": {"cat": "Both", "light": "Bright Direct", "water": "Low", "diff": "Easy", "tox": "Varies"},
    "Cacti": {"cat": "Both", "light": "Full Sun", "water": "Very Low", "diff": "Easy", "tox": "Low"},
    "Ferns": {"cat": "Both", "light": "Shade/Indirect", "water": "High", "diff": "Medium", "tox": False},
    "Palms": {"cat": "Both", "light": "Bright Indirect", "water": "Moderate", "diff": "Medium", "tox": False},
    "Begonia": {"cat": "Indoor", "light": "Bright Indirect", "water": "Moderate", "diff": "Medium", "tox": True},
    "Tradescantia": {"cat": "Indoor", "light": "Bright Indirect", "water": "Moderate", "diff": "Easy", "tox": True},
    "Herbs (Indoor/Outdoor)": {"cat": "Both", "light": "Full Sun", "water": "Moderate", "diff": "Medium", "tox": False},
    "Outdoor Flowers (Container)": {"cat": "Outdoor", "light": "Full Sun", "water": "High", "diff": "Easy", "tox": "Varies"},
    "Trees/Shrubs (Outdoor Container)": {"cat": "Outdoor", "light": "Full Sun/Part Shade", "water": "Moderate", "diff": "Medium", "tox": "Varies"}
}

plants_list = []
id_counter = 1

for genus, species_list in plant_database.items():
    care = care_guides.get(genus, {"cat": "Unknown", "light": "Unknown", "water": "Unknown", "diff": "Unknown", "tox": "Unknown"})
    
    for species in species_list:
        name = f"{genus} {species}"
        
        # Basic logic to assign ID and structure
        plant_entry = {
            "id": id_counter,
            "common_name": name,
            "genus": genus,
            "category": care["cat"],
            "light_requirements": care["light"],
            "watering_needs": care["water"],
            "care_difficulty": care["diff"],
            "toxicity": "Toxic" if care["tox"] is True else ("Non-Toxic" if care["tox"] is False else care["tox"])
        }
        plants_list.append(plant_entry)
        id_counter += 1

output_data = {
    "metadata": {
        "title": "Extensive Plant Database",
        "total_count": len(plants_list),
        "description": "A comprehensive list of indoor and outdoor plants suitable for home/containers."
    },
    "plants": plants_list
}

# Write to file
filename = "extensive_plants.json"
with open(filename, "w") as f:
    json.dump(output_data, f, indent=2)

print(f"Successfully created {filename} with {len(plants_list)} plant entries.")