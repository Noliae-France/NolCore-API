# Politique de sécurité

## Signaler une vulnérabilité

Ne publiez pas de vulnérabilité exploitable dans une issue publique. Utilisez une GitHub Private Vulnerability Report si elle est disponible dans l’onglet Security du dépôt. À défaut, écrivez à [bastien@languedoc.ovh](mailto:bastien@languedoc.ovh) avec la version, l’impact et les étapes de reproduction.

N’incluez jamais de mot de passe, token API, clé privée ou donnée personnelle réelle dans votre rapport.

## Périmètre

Le code Nolc, l’image Docker, les manifests Kubernetes/K3s, l’authentification, les sessions, PostgreSQL et SMTP sont dans le périmètre.

## Déploiement

- ne commitez aucun secret ;
- utilisez un Secret Kubernetes ou un coffre-fort ;
- utilisez un secret de session aléatoire d’au moins 32 caractères ;
- utilisez SMTP 465 avec TLS implicite ou 587 avec STARTTLS ;
- placez l’API derrière TLS en production ;
- limitez les permissions PostgreSQL et Kubernetes.

La branche `main` est la version de référence.
