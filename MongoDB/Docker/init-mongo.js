// Connexion avec les credentials admin
db = db.getSiblingDB('ecommerce');

// ========================================
// COLLECTION: categories
// ========================================
db.categories.insertMany([
    {
        "_id": ObjectId("650a11111111111111110001"),
        "name": "Électronique",
        "slug": "electronique",
        "description": "Appareils électroniques et accessoires",
        "parent": null,
        "createdAt": new Date("2024-01-15")
    },
    {
        "_id": ObjectId("650a11111111111111110002"),
        "name": "Informatique",
        "slug": "informatique",
        "description": "Ordinateurs, périphériques et composants",
        "parent": ObjectId("650a11111111111111110001"),
        "createdAt": new Date("2024-01-15")
    },
    {
        "_id": ObjectId("650a11111111111111110003"),
        "name": "Smartphones",
        "slug": "smartphones",
        "description": "Téléphones intelligents et accessoires",
        "parent": ObjectId("650a11111111111111110001"),
        "createdAt": new Date("2024-01-15")
    },
    {
        "_id": ObjectId("650a11111111111111110004"),
        "name": "Vêtements",
        "slug": "vetements",
        "description": "Mode et accessoires vestimentaires",
        "parent": null,
        "createdAt": new Date("2024-01-15")
    },
    {
        "_id": ObjectId("650a11111111111111110005"),
        "name": "Livres",
        "slug": "livres",
        "description": "Livres et publications",
        "parent": null,
        "createdAt": new Date("2024-01-15")
    }
]);

// ========================================
// COLLECTION: products
// ========================================
db.products.insertMany([
    {
        "_id": ObjectId("650a22222222222222220001"),
        "name": "Ordinateur portable XPS 15",
        "slug": "ordinateur-portable-xps-15",
        "description": "Ordinateur portable haute performance avec écran 15 pouces",
        "category": ObjectId("650a11111111111111110002"),
        "price": 1299.99,
        "currency": "EUR",
        "stock": 45,
        "sku": "LAPTOP-XPS15-001",
        "images": [
            "https://example.com/images/xps15-front.jpg",
            "https://example.com/images/xps15-side.jpg",
            "https://example.com/images/xps15-back.jpg"
        ],
        "specifications": {
            "brand": "Dell",
            "processor": "Intel Core i7-13700H",
            "ram": "16GB DDR5",
            "storage": "512GB SSD",
            "screen": "15.6 pouces FHD",
            "weight": "1.86kg"
        },
        "tags": ["laptop", "informatique", "portable", "gaming"],
        "reviews": [
            {
                "customer_id": ObjectId("650a33333333333333330001"),
                "rating": 5,
                "comment": "Excellent ordinateur, très rapide et silencieux",
                "date": new Date("2024-09-15"),
                "verified_purchase": true
            },
            {
                "customer_id": ObjectId("650a33333333333333330002"),
                "rating": 4,
                "comment": "Bon produit mais un peu cher",
                "date": new Date("2024-09-20"),
                "verified_purchase": true
            }
        ],
        "rating": {
            "average": 4.5,
            "count": 2
        },
        "isActive": true,
        "createdAt": new Date("2024-08-01"),
        "updatedAt": new Date("2024-09-20")
    },
    {
        "_id": ObjectId("650a22222222222222220002"),
        "name": "Smartphone Galaxy S24",
        "slug": "smartphone-galaxy-s24",
        "description": "Smartphone haut de gamme avec appareil photo 200MP",
        "category": ObjectId("650a11111111111111110003"),
        "price": 899.99,
        "currency": "EUR",
        "stock": 120,
        "sku": "PHONE-GALAXY-S24",
        "images": [
            "https://example.com/images/galaxy-s24-black.jpg",
            "https://example.com/images/galaxy-s24-white.jpg"
        ],
        "specifications": {
            "brand": "Samsung",
            "screen": "6.2 pouces AMOLED",
            "processor": "Snapdragon 8 Gen 3",
            "ram": "8GB",
            "storage": "256GB",
            "camera": "200MP + 12MP + 10MP",
            "battery": "4000mAh"
        },
        "variants": [
            {
                "color": "Noir",
                "storage": "256GB",
                "price": 899.99,
                "sku": "PHONE-GALAXY-S24-BLK-256",
                "stock": 50
            },
            {
                "color": "Blanc",
                "storage": "256GB",
                "price": 899.99,
                "sku": "PHONE-GALAXY-S24-WHT-256",
                "stock": 40
            },
            {
                "color": "Noir",
                "storage": "512GB",
                "price": 1099.99,
                "sku": "PHONE-GALAXY-S24-BLK-512",
                "stock": 30
            }
        ],
        "tags": ["smartphone", "samsung", "android", "5g"],
        "reviews": [
            {
                "customer_id": ObjectId("650a33333333333333330003"),
                "rating": 5,
                "comment": "Meilleur smartphone que j'ai eu, photos incroyables",
                "date": new Date("2024-10-01"),
                "verified_purchase": true
            }
        ],
        "rating": {
            "average": 5,
            "count": 1
        },
        "isActive": true,
        "createdAt": new Date("2024-08-15"),
        "updatedAt": new Date("2024-10-01")
    },
    {
        "_id": ObjectId("650a22222222222222220003"),
        "name": "Clavier mécanique RGB",
        "slug": "clavier-mecanique-rgb",
        "description": "Clavier mécanique avec rétroéclairage RGB personnalisable",
        "category": ObjectId("650a11111111111111110002"),
        "price": 129.99,
        "currency": "EUR",
        "stock": 200,
        "sku": "KEYB-MECH-RGB-001",
        "images": [
            "https://example.com/images/keyboard-rgb.jpg"
        ],
        "specifications": {
            "brand": "Corsair",
            "type": "Mécanique",
            "switches": "Cherry MX Red",
            "backlighting": "RGB",
            "connectivity": "USB-C"
        },
        "tags": ["clavier", "gaming", "rgb", "mécanique"],
        "reviews": [],
        "rating": {
            "average": 0,
            "count": 0
        },
        "isActive": true,
        "createdAt": new Date("2024-09-01"),
        "updatedAt": new Date("2024-09-01")
    },
    {
        "_id": ObjectId("650a22222222222222220004"),
        "name": "T-shirt coton bio",
        "slug": "t-shirt-coton-bio",
        "description": "T-shirt en coton biologique, confortable et écologique",
        "category": ObjectId("650a11111111111111110004"),
        "price": 29.99,
        "currency": "EUR",
        "stock": 500,
        "sku": "TSHIRT-BIO-001",
        "images": [
            "https://example.com/images/tshirt-blue.jpg",
            "https://example.com/images/tshirt-red.jpg"
        ],
        "specifications": {
            "brand": "EcoWear",
            "material": "100% coton bio",
            "care": "Lavage à 30°C"
        },
        "variants": [
            {
                "color": "Bleu",
                "size": "S",
                "sku": "TSHIRT-BIO-BLU-S",
                "stock": 80
            },
            {
                "color": "Bleu",
                "size": "M",
                "sku": "TSHIRT-BIO-BLU-M",
                "stock": 100
            },
            {
                "color": "Bleu",
                "size": "L",
                "sku": "TSHIRT-BIO-BLU-L",
                "stock": 70
            },
            {
                "color": "Rouge",
                "size": "S",
                "sku": "TSHIRT-BIO-RED-S",
                "stock": 90
            },
            {
                "color": "Rouge",
                "size": "M",
                "sku": "TSHIRT-BIO-RED-M",
                "stock": 100
            },
            {
                "color": "Rouge",
                "size": "L",
                "sku": "TSHIRT-BIO-RED-L",
                "stock": 60
            }
        ],
        "tags": ["vêtement", "bio", "écologique", "coton"],
        "reviews": [
            {
                "customer_id": ObjectId("650a33333333333333330004"),
                "rating": 4,
                "comment": "Bonne qualité, taille bien",
                "date": new Date("2024-10-10"),
                "verified_purchase": true
            }
        ],
        "rating": {
            "average": 4,
            "count": 1
        },
        "isActive": true,
        "createdAt": new Date("2024-07-01"),
        "updatedAt": new Date("2024-10-10")
    },
    {
        "_id": ObjectId("650a22222222222222220005"),
        "name": "MongoDB - Guide du développeur",
        "slug": "mongodb-guide-developpeur",
        "description": "Guide complet pour maîtriser MongoDB",
        "category": ObjectId("650a11111111111111110005"),
        "price": 45.00,
        "currency": "EUR",
        "stock": 75,
        "sku": "BOOK-MONGO-001",
        "images": [
            "https://example.com/images/book-mongodb.jpg"
        ],
        "specifications": {
            "author": "Jean Dupont",
            "publisher": "Éditions Tech",
            "isbn": "978-3-16-148410-0",
            "pages": 450,
            "language": "Français",
            "format": "Broché"
        },
        "tags": ["livre", "mongodb", "base de données", "développement"],
        "reviews": [],
        "rating": {
            "average": 0,
            "count": 0
        },
        "isActive": true,
        "createdAt": new Date("2024-06-01"),
        "updatedAt": new Date("2024-06-01")
    }
]);

// ========================================
// COLLECTION: customers
// ========================================
db.customers.insertMany([
    {
        "_id": ObjectId("650a33333333333333330001"),
        "firstName": "Pierre",
        "lastName": "Martin",
        "email": "pierre.martin@email.fr",
        "password": "$2b$10$abcdefghijklmnopqrstuv",
        "phone": "+33612345678",
        "addresses": [
            {
                "type": "billing",
                "street": "15 rue de la République",
                "city": "Lyon",
                "postalCode": "69002",
                "country": "France",
                "isDefault": true
            },
            {
                "type": "shipping",
                "street": "15 rue de la République",
                "city": "Lyon",
                "postalCode": "69002",
                "country": "France",
                "isDefault": true
            }
        ],
        "preferences": {
            "newsletter": true,
            "language": "fr",
            "currency": "EUR"
        },
        "statistics": {
            "totalOrders": 3,
            "totalSpent": 2549.95,
            "averageOrderValue": 849.98
        },
        "isActive": true,
        "emailVerified": true,
        "createdAt": new Date("2024-05-10"),
        "lastLogin": new Date("2024-10-15")
    },
    {
        "_id": ObjectId("650a33333333333333330002"),
        "firstName": "Marie",
        "lastName": "Dubois",
        "email": "marie.dubois@email.fr",
        "password": "$2b$10$wxyzabcdefghijklmnopqr",
        "phone": "+33623456789",
        "addresses": [
            {
                "type": "billing",
                "street": "42 avenue des Champs-Élysées",
                "city": "Paris",
                "postalCode": "75008",
                "country": "France",
                "isDefault": true
            },
            {
                "type": "shipping",
                "street": "8 rue de Rivoli",
                "city": "Paris",
                "postalCode": "75004",
                "country": "France",
                "isDefault": false
            }
        ],
        "preferences": {
            "newsletter": true,
            "language": "fr",
            "currency": "EUR"
        },
        "statistics": {
            "totalOrders": 1,
            "totalSpent": 899.99,
            "averageOrderValue": 899.99
        },
        "isActive": true,
        "emailVerified": true,
        "createdAt": new Date("2024-06-15"),
        "lastLogin": new Date("2024-09-22")
    },
    {
        "_id": ObjectId("650a33333333333333330003"),
        "firstName": "Jean",
        "lastName": "Lefebvre",
        "email": "jean.lefebvre@email.fr",
        "password": "$2b$10$zyxwvutsrqponmlkjihgf",
        "phone": "+33634567890",
        "addresses": [
            {
                "type": "billing",
                "street": "123 boulevard de la Croisette",
                "city": "Cannes",
                "postalCode": "06400",
                "country": "France",
                "isDefault": true
            }
        ],
        "preferences": {
            "newsletter": false,
            "language": "fr",
            "currency": "EUR"
        },
        "statistics": {
            "totalOrders": 1,
            "totalSpent": 1044.98,
            "averageOrderValue": 1044.98
        },
        "isActive": true,
        "emailVerified": true,
        "createdAt": new Date("2024-07-20"),
        "lastLogin": new Date("2024-10-01")
    },
    {
        "_id": ObjectId("650a33333333333333330004"),
        "firstName": "Sophie",
        "lastName": "Petit",
        "email": "sophie.petit@email.fr",
        "password": "$2b$10$fedcbazyxwvutsrqponmlk",
        "phone": "+33645678901",
        "addresses": [
            {
                "type": "billing",
                "street": "7 place de la Comédie",
                "city": "Montpellier",
                "postalCode": "34000",
                "country": "France",
                "isDefault": true
            }
        ],
        "preferences": {
            "newsletter": true,
            "language": "fr",
            "currency": "EUR"
        },
        "statistics": {
            "totalOrders": 2,
            "totalSpent": 112.95,
            "averageOrderValue": 56.48
        },
        "isActive": true,
        "emailVerified": true,
        "createdAt": new Date("2024-08-05"),
        "lastLogin": new Date("2024-10-20")
    },
    {
        "_id": ObjectId("650a33333333333333330005"),
        "firstName": "Thomas",
        "lastName": "Robert",
        "email": "thomas.robert@email.fr",
        "password": "$2b$10$jihgfedcbazyxwvutsrqpo",
        "phone": "+33656789012",
        "addresses": [
            {
                "type": "billing",
                "street": "31 rue Nationale",
                "city": "Lille",
                "postalCode": "59000",
                "country": "France",
                "isDefault": true
            }
        ],
        "preferences": {
            "newsletter": false,
            "language": "fr",
            "currency": "EUR"
        },
        "statistics": {
            "totalOrders": 1,
            "totalSpent": 58.99,
            "averageOrderValue": 58.99
        },
        "isActive": true,
        "emailVerified": true,
        "createdAt": new Date("2024-09-01"),
        "lastLogin": new Date("2024-10-03")
    }
]);

// ========================================
// COLLECTION: orders
// ========================================
db.orders.insertMany([
    {
        "_id": ObjectId("650a44444444444444440001"),
        "orderNumber": "ORD-2024-001",
        "customer_id": ObjectId("650a33333333333333330001"),
        "orderDate": new Date("2024-09-20"),
        "status": "delivered",
        "items": [
            {
                "product_id": ObjectId("650a22222222222222220001"),
                "name": "Ordinateur portable XPS 15",
                "sku": "LAPTOP-XPS15-001",
                "quantity": 1,
                "unitPrice": 1299.99,
                "totalPrice": 1299.99
            }
        ],
        "shippingAddress": {
            "firstName": "Pierre",
            "lastName": "Martin",
            "street": "15 rue de la République",
            "city": "Lyon",
            "postalCode": "69002",
            "country": "France",
            "phone": "+33612345678"
        },
        "billingAddress": {
            "firstName": "Pierre",
            "lastName": "Martin",
            "street": "15 rue de la République",
            "city": "Lyon",
            "postalCode": "69002",
            "country": "France"
        },
        "payment": {
            "method": "credit_card",
            "status": "paid",
            "transactionId": "TRX-20240920-001",
            "paidAt": new Date("2024-09-20T10:15:00")
        },
        "pricing": {
            "subtotal": 1299.99,
            "shipping": 0.00,
            "tax": 260.00,
            "discount": 0.00,
            "total": 1559.99
        },
        "shipping": {
            "carrier": "DHL Express",
            "trackingNumber": "1Z9999999999999999",
            "shippedAt": new Date("2024-09-21T09:00:00"),
            "deliveredAt": new Date("2024-09-23T14:30:00")
        },
        "timeline": [
            {
                "status": "pending",
                "date": new Date("2024-09-20T10:15:00"),
                "note": "Commande créée"
            },
            {
                "status": "processing",
                "date": new Date("2024-09-20T10:20:00"),
                "note": "Paiement confirmé"
            },
            {
                "status": "shipped",
                "date": new Date("2024-09-21T09:00:00"),
                "note": "Colis expédié"
            },
            {
                "status": "delivered",
                "date": new Date("2024-09-23T14:30:00"),
                "note": "Colis livré"
            }
        ],
        "createdAt": new Date("2024-09-20T10:15:00"),
        "updatedAt": new Date("2024-09-23T14:30:00")
    },
    {
        "_id": ObjectId("650a44444444444444440002"),
        "orderNumber": "ORD-2024-002",
        "customer_id": ObjectId("650a33333333333333330002"),
        "orderDate": new Date("2024-09-22"),
        "status": "delivered",
        "items": [
            {
                "product_id": ObjectId("650a22222222222222220002"),
                "name": "Smartphone Galaxy S24",
                "sku": "PHONE-GALAXY-S24-BLK-256",
                "quantity": 1,
                "unitPrice": 899.99,
                "totalPrice": 899.99,
                "variant": {
                    "color": "Noir",
                    "storage": "256GB"
                }
            }
        ],
        "shippingAddress": {
            "firstName": "Marie",
            "lastName": "Dubois",
            "street": "8 rue de Rivoli",
            "city": "Paris",
            "postalCode": "75004",
            "country": "France",
            "phone": "+33623456789"
        },
        "billingAddress": {
            "firstName": "Marie",
            "lastName": "Dubois",
            "street": "42 avenue des Champs-Élysées",
            "city": "Paris",
            "postalCode": "75008",
            "country": "France"
        },
        "payment": {
            "method": "paypal",
            "status": "paid",
            "transactionId": "PAYPAL-20240922-001",
            "paidAt": new Date("2024-09-22T14:30:00")
        },
        "pricing": {
            "subtotal": 899.99,
            "shipping": 5.99,
            "tax": 180.00,
            "discount": 0.00,
            "total": 1085.98
        },
        "shipping": {
            "carrier": "Chronopost",
            "trackingNumber": "XY123456789FR",
            "shippedAt": new Date("2024-09-23T08:00:00"),
            "deliveredAt": new Date("2024-09-24T11:00:00")
        },
        "timeline": [
            {
                "status": "pending",
                "date": new Date("2024-09-22T14:30:00"),
                "note": "Commande créée"
            },
            {
                "status": "processing",
                "date": new Date("2024-09-22T14:35:00"),
                "note": "Paiement PayPal confirmé"
            },
            {
                "status": "shipped",
                "date": new Date("2024-09-23T08:00:00"),
                "note": "Colis expédié"
            },
            {
                "status": "delivered",
                "date": new Date("2024-09-24T11:00:00"),
                "note": "Colis livré"
            }
        ],
        "createdAt": new Date("2024-09-22T14:30:00"),
        "updatedAt": new Date("2024-09-24T11:00:00")
    },
    {
        "_id": ObjectId("650a44444444444444440003"),
        "orderNumber": "ORD-2024-003",
        "customer_id": ObjectId("650a33333333333333330003"),
        "orderDate": new Date("2024-10-01"),
        "status": "delivered",
        "items": [
            {
                "product_id": ObjectId("650a22222222222222220002"),
                "name": "Smartphone Galaxy S24",
                "sku": "PHONE-GALAXY-S24-BLK-512",
                "quantity": 1,
                "unitPrice": 1099.99,
                "totalPrice": 1099.99,
                "variant": {
                    "color": "Noir",
                    "storage": "512GB"
                }
            }
        ],
        "shippingAddress": {
            "firstName": "Jean",
            "lastName": "Lefebvre",
            "street": "123 boulevard de la Croisette",
            "city": "Cannes",
            "postalCode": "06400",
            "country": "France",
            "phone": "+33634567890"
        },
        "billingAddress": {
            "firstName": "Jean",
            "lastName": "Lefebvre",
            "street": "123 boulevard de la Croisette",
            "city": "Cannes",
            "postalCode": "06400",
            "country": "France"
        },
        "payment": {
            "method": "credit_card",
            "status": "paid",
            "transactionId": "TRX-20241001-002",
            "paidAt": new Date("2024-10-01T16:45:00")
        },
        "pricing": {
            "subtotal": 1099.99,
            "shipping": 0.00,
            "tax": 220.00,
            "discount": 50.00,
            "total": 1269.99
        },
        "shipping": {
            "carrier": "UPS",
            "trackingNumber": "1Z999AA10123456784",
            "shippedAt": new Date("2024-10-02T10:00:00"),
            "deliveredAt": new Date("2024-10-04T15:20:00")
        },
        "timeline": [
            {
                "status": "pending",
                "date": new Date("2024-10-01T16:45:00"),
                "note": "Commande créée"
            },
            {
                "status": "processing",
                "date": new Date("2024-10-01T16:50:00"),
                "note": "Paiement confirmé"
            },
            {
                "status": "shipped",
                "date": new Date("2024-10-02T10:00:00"),
                "note": "Colis expédié"
            },
            {
                "status": "delivered",
                "date": new Date("2024-10-04T15:20:00"),
                "note": "Colis livré"
            }
        ],
        "couponCode": "FIRST50",
        "createdAt": new Date("2024-10-01T16:45:00"),
        "updatedAt": new Date("2024-10-04T15:20:00")
    },
    {
        "_id": ObjectId("650a44444444444444440004"),
        "orderNumber": "ORD-2024-004",
        "customer_id": ObjectId("650a33333333333333330001"),
        "orderDate": new Date("2024-10-05"),
        "status": "shipped",
        "items": [
            {
                "product_id": ObjectId("650a22222222222222220001"),
                "name": "Ordinateur portable XPS 15",
                "sku": "LAPTOP-XPS15-001",
                "quantity": 1,
                "unitPrice": 1299.99,
                "totalPrice": 1299.99
            },
            {
                "product_id": ObjectId("650a22222222222222220003"),
                "name": "Clavier mécanique RGB",
                "sku": "KEYB-MECH-RGB-001",
                "quantity": 1,
                "unitPrice": 129.99,
                "totalPrice": 129.99
            }
        ],
        "shippingAddress": {
            "firstName": "Pierre",
            "lastName": "Martin",
            "street": "15 rue de la République",
            "city": "Lyon",
            "postalCode": "69002",
            "country": "France",
            "phone": "+33612345678"
        },
        "billingAddress": {
            "firstName": "Pierre",
            "lastName": "Martin",
            "street": "15 rue de la République",
            "city": "Lyon",
            "postalCode": "69002",
            "country": "France"
        },
        "payment": {
            "method": "credit_card",
            "status": "paid",
            "transactionId": "TRX-20241005-003",
            "paidAt": new Date("2024-10-05T09:00:00")
        },
        "pricing": {
            "subtotal": 1429.98,
            "shipping": 0.00,
            "tax": 286.00,
            "discount": 0.00,
            "total": 1715.98
        },
        "shipping": {
            "carrier": "DHL Express",
            "trackingNumber": "1Z9999999999999998",
            "shippedAt": new Date("2024-10-06T08:30:00")
        },
        "timeline": [
            {
                "status": "pending",
                "date": new Date("2024-10-05T09:00:00"),
                "note": "Commande créée"
            },
            {
                "status": "processing",
                "date": new Date("2024-10-05T09:05:00"),
                "note": "Paiement confirmé"
            },
            {
                "status": "shipped",
                "date": new Date("2024-10-06T08:30:00"),
                "note": "Colis expédié"
            }
        ],
        "createdAt": new Date("2024-10-05T09:00:00"),
        "updatedAt": new Date("2024-10-06T08:30:00")
    },
    {
        "_id": ObjectId("650a44444444444444440005"),
        "orderNumber": "ORD-2024-005",
        "customer_id": ObjectId("650a33333333333333330004"),
        "orderDate": new Date("2024-10-08"),
        "status": "delivered",
        "items": [
            {
                "product_id": ObjectId("650a22222222222222220004"),
                "name": "T-shirt coton bio",
                "sku": "TSHIRT-BIO-BLU-M",
                "quantity": 2,
                "unitPrice": 29.99,
                "totalPrice": 59.98,
                "variant": {
                    "color": "Bleu",
                    "size": "M"
                }
            }
        ],
        "shippingAddress": {
            "firstName": "Sophie",
            "lastName": "Petit",
            "street": "7 place de la Comédie",
            "city": "Montpellier",
            "postalCode": "34000",
            "country": "France",
            "phone": "+33645678901"
        },
        "billingAddress": {
            "firstName": "Sophie",
            "lastName": "Petit",
            "street": "7 place de la Comédie",
            "city": "Montpellier",
            "postalCode": "34000",
            "country": "France"
        },
        "payment": {
            "method": "credit_card",
            "status": "paid",
            "transactionId": "TRX-20241008-004",
            "paidAt": new Date("2024-10-08T09:30:00")
        },
        "pricing": {
            "subtotal": 59.98,
            "shipping": 4.99,
            "tax": 12.00,
            "discount": 5.00,
            "total": 71.97
        },
        "shipping": {
            "carrier": "La Poste",
            "trackingNumber": "8L01234567890",
            "shippedAt": new Date("2024-10-09T08:00:00"),
            "deliveredAt": new Date("2024-10-11T10:45:00")
        },
        "timeline": [
            {
                "status": "pending",
                "date": new Date("2024-10-08T09:30:00"),
                "note": "Commande créée"
            },
            {
                "status": "processing",
                "date": new Date("2024-10-08T09:35:00"),
                "note": "Paiement confirmé"
            },
            {
                "status": "shipped",
                "date": new Date("2024-10-09T08:00:00"),
                "note": "Colis expédié"
            },
            {
                "status": "delivered",
                "date": new Date("2024-10-11T10:45:00"),
                "note": "Colis livré"
            }
        ],
        "couponCode": "WELCOME5",
        "createdAt": new Date("2024-10-08T09:30:00"),
        "updatedAt": new Date("2024-10-11T10:45:00")
    },
    {
        "_id": ObjectId("650a44444444444444440006"),
        "orderNumber": "ORD-2024-006",
        "customer_id": ObjectId("650a33333333333333330005"),
        "orderDate": new Date("2024-10-03"),
        "status": "delivered",
        "items": [
            {
                "product_id": ObjectId("650a22222222222222220005"),
                "name": "MongoDB - Guide du développeur",
                "sku": "BOOK-MONGO-001",
                "quantity": 1,
                "unitPrice": 45.00,
                "totalPrice": 45.00
            }
        ],
        "shippingAddress": {
            "firstName": "Thomas",
            "lastName": "Robert",
            "street": "31 rue Nationale",
            "city": "Lille",
            "postalCode": "59000",
            "country": "France",
            "phone": "+33656789012"
        },
        "billingAddress": {
            "firstName": "Thomas",
            "lastName": "Robert",
            "street": "31 rue Nationale",
            "city": "Lille",
            "postalCode": "59000",
            "country": "France"
        },
        "payment": {
            "method": "credit_card",
            "status": "paid",
            "transactionId": "TRX-20241003-005",
            "paidAt": new Date("2024-10-03T14:50:00")
        },
        "pricing": {
            "subtotal": 45.00,
            "shipping": 4.99,
            "tax": 9.00,
            "discount": 0.00,
            "total": 58.99
        },
        "shipping": {
            "carrier": "Colissimo",
            "trackingNumber": "6A98765432109",
            "shippedAt": new Date("2024-10-04T09:30:00"),
            "deliveredAt": new Date("2024-10-06T16:00:00")
        },
        "timeline": [
            {
                "status": "pending",
                "date": new Date("2024-10-03T14:50:00"),
                "note": "Commande créée"
            },
            {
                "status": "processing",
                "date": new Date("2024-10-03T15:00:00"),
                "note": "Paiement confirmé"
            },
            {
                "status": "shipped",
                "date": new Date("2024-10-04T09:30:00"),
                "note": "Colis expédié"
            },
            {
                "status": "delivered",
                "date": new Date("2024-10-06T16:00:00"),
                "note": "Colis livré"
            }
        ],
        "createdAt": new Date("2024-10-03T14:50:00"),
        "updatedAt": new Date("2024-10-06T16:00:00")
    },
    {
        "_id": ObjectId("650a44444444444444440007"),
        "orderNumber": "ORD-2024-007",
        "customer_id": ObjectId("650a33333333333333330001"),
        "orderDate": new Date("2024-10-15"),
        "status": "processing",
        "items": [
            {
                "product_id": ObjectId("650a22222222222222220003"),
                "name": "Clavier mécanique RGB",
                "sku": "KEYB-MECH-RGB-001",
                "quantity": 1,
                "unitPrice": 129.99,
                "totalPrice": 129.99
            },
            {
                "product_id": ObjectId("650a22222222222222220004"),
                "name": "T-shirt coton bio",
                "sku": "TSHIRT-BIO-RED-L",
                "quantity": 1,
                "unitPrice": 29.99,
                "totalPrice": 29.99,
                "variant": {
                    "color": "Rouge",
                    "size": "L"
                }
            }
        ],
        "shippingAddress": {
            "firstName": "Pierre",
            "lastName": "Martin",
            "street": "15 rue de la République",
            "city": "Lyon",
            "postalCode": "69002",
            "country": "France",
            "phone": "+33612345678"
        },
        "billingAddress": {
            "firstName": "Pierre",
            "lastName": "Martin",
            "street": "15 rue de la République",
            "city": "Lyon",
            "postalCode": "69002",
            "country": "France"
        },
        "payment": {
            "method": "credit_card",
            "status": "paid",
            "transactionId": "TRX-20241015-006",
            "paidAt": new Date("2024-10-15T11:20:00")
        },
        "pricing": {
            "subtotal": 159.98,
            "shipping": 5.99,
            "tax": 32.00,
            "discount": 10.00,
            "total": 187.97
        },
        "timeline": [
            {
                "status": "pending",
                "date": new Date("2024-10-15T11:20:00"),
                "note": "Commande créée"
            },
            {
                "status": "processing",
                "date": new Date("2024-10-15T11:25:00"),
                "note": "Paiement confirmé, en préparation"
            }
        ],
        "couponCode": "FIDELITE10",
        "createdAt": new Date("2024-10-15T11:20:00"),
        "updatedAt": new Date("2024-10-15T11:25:00")
    },
    {
        "_id": ObjectId("650a44444444444444440008"),
        "orderNumber": "ORD-2024-008",
        "customer_id": ObjectId("650a33333333333333330004"),
        "orderDate": new Date("2024-10-20"),
        "status": "pending",
        "items": [
            {
                "product_id": ObjectId("650a22222222222222220004"),
                "name": "T-shirt coton bio",
                "sku": "TSHIRT-BIO-BLU-S",
                "quantity": 1,
                "unitPrice": 29.99,
                "totalPrice": 29.99,
                "variant": {
                    "color": "Bleu",
                    "size": "S"
                }
            }
        ],
        "shippingAddress": {
            "firstName": "Sophie",
            "lastName": "Petit",
            "street": "7 place de la Comédie",
            "city": "Montpellier",
            "postalCode": "34000",
            "country": "France",
            "phone": "+33645678901"
        },
        "billingAddress": {
            "firstName": "Sophie",
            "lastName": "Petit",
            "street": "7 place de la Comédie",
            "city": "Montpellier",
            "postalCode": "34000",
            "country": "France"
        },
        "payment": {
            "method": "bank_transfer",
            "status": "pending"
        },
        "pricing": {
            "subtotal": 29.99,
            "shipping": 4.99,
            "tax": 6.00,
            "discount": 0.00,
            "total": 40.98
        },
        "timeline": [
            {
                "status": "pending",
                "date": new Date("2024-10-20T15:30:00"),
                "note": "Commande créée, en attente de paiement"
            }
        ],
        "createdAt": new Date("2024-10-20T15:30:00"),
        "updatedAt": new Date("2024-10-20T15:30:00")
    }
]);