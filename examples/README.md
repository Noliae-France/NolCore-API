# Exemples NolCore

Ce dossier contient des exemples de clients et de présentation du core. Ils ne
font pas partie du binaire API Docker ou Kubernetes.

## MVC indicatif

Le sous-dossier [`mvc`](mvc) contient des vues `.nhtml`, leurs sorties Nolc et
un CSS de démonstration pour :

- l’accueil ;
- l’inscription ;
- la connexion ;
- la recherche ;
- le tableau de bord.

Ces fichiers servent de base pour une application frontend séparée. Une
application de production doit appeler les routes `/v1/*` documentées dans le
README du dépôt.
