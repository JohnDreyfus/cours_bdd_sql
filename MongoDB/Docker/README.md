### Vérifications

```bash
# Se connecter au conteneur
docker exec -it mongodb mongosh -u admin -p password

# Dans le shell MongoDB
use ecommerce
show collections
db.products.countDocuments() # resultat 5
db.customers.countDocuments() # resultat 5
db.orders.countDocuments() # resultat 8
db.categories.countDocuments() # resultat 5
```