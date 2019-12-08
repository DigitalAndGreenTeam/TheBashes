La trame : 

Récolte des infos basiques des machines
Json + Logs

Implémentation et déploiement temporaires (/tmp) puis suppression après opérations de récolte
Rappel de droits de copyright

[on ne prend pas les IPs
en remontée d'informations, on code les noms des machines en alphanumérique aléatoire
on a un tableau de conversion conservée par le client pour qu'il puisse faire le lien facilement (csv pour tableau Excel ensuite ?)]

Ensuite on renseigne la BDD


#1 Référentiel : 
Afin d'avoir des éléments de comparaison, il est nécessaire d'avoir un référentiel à jour
On crée une référence dans la BDD et on l'alimente automatiquement via des scripts spécifiques
Pour vérifier les mises à jour, on lance des scripts à chaque lancement de l'application en front

