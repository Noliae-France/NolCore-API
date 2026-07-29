<div align="center">

# ◈ NolCore API

## NolCore-API — gateway public

Ce dépôt est le gateway API et le service d’identité/administration. Le
crawler et l’agrégateur IA sont des binaires et dépôts séparés. Configurez
`NOLCORE_CRAWLER_URL` et `NOLCORE_IA_URL` pour déléguer leurs routes au réseau
interne Kubernetes.

### Le cœur open source de Noliae

Un backend MVC natif en **Nolc** pour construire les services de [noliae.com](https://noliae.com) : identité, IA, recherche, crawling et intégrations.

[![CI](https://github.com/Noliae-France/NolCore/actions/workflows/ci.yml/badge.svg)](https://github.com/Noliae-France/NolCore/actions/workflows/ci.yml)
[![Runtime](https://img.shields.io/badge/runtime-Nolc%20native-ff4d2e)](https://github.com/Noliae-France/nolc)
[![Database](https://img.shields.io/badge/database-PostgreSQL-336791)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/license-MIT-2ea44f)](LICENSE)

</div>

## Pourquoi NolCore ?

NolCore API est le gateway métier des applications Noliae : sécurité, comptes,
permissions, recherche PostgreSQL, sessions, administration et intégrations.
Il ne contient ni moteur de crawling ni connecteurs de fournisseurs IA.

Les appels IA sont délégués à
[NolCore-IA](https://github.com/Noliae-France/NolCore-IA) par `NOLCORE_IA_URL`
et le crawling à
[NolCore-Crawler](https://github.com/Noliae-France/NolCore-Crawler) par
`NOLCORE_CRAWLER_URL`.

Nous avons décidé de montrer le code source de nos apps et de notre cœur :
la transparence permet aux utilisateurs, développeurs et auditeurs de comprendre
les garanties du produit, de proposer des améliorations et de construire avec
Noliae plutôt que de dépendre d’une boîte noire.

## Fonctionnalités

| Domaine | Ce que fournit NolCore |
|---|---|
| API | Routeur Nolc, contrôleurs, PostgreSQL et services natifs |
| Users & Auth | Inscription, connexion, profil, changement de compte, sessions 24 h |
| Sessions | Cookie signé lié à l’utilisateur, l’email, l’IP, l’horodatage et un nonce aléatoire |
| IA | Routage authentifié vers NolCore-IA |
| Recherche | Index PostgreSQL plein texte, recherche textuelle, IA et base pour images |
| Crawler | Routage authentifié vers NolCore-Crawler |
| Permissions | Permissions par utilisateur, rôles et audit des actions |
| Administration | Gestion des utilisateurs et supervision du cœur |
| Intégrations | Bot Discord et webhook Discord configurables |

## Architecture

```text
NolCore API
├── main.nol                 # routeur + boucle HTTP
├── schema.sql               # PostgreSQL et migrations initiales
├── vendor/nolc/lib/         # stdlib Nolc compatible avec le binaire public
├── Dockerfile
└── docker-compose.yml
```

Le serveur est un binaire natif Nolc. PostgreSQL est le seul service de
persistance ; les requêtes venant de l’extérieur passent par des paramètres
libpq et ne sont pas concaténées au SQL.

### Kubernetes / K3s

Le dossier `deploy/k8s/base` fournit un déploiement Kustomize avec deux
réplicas API, PostgreSQL persistant, probes `/api/health` et `/api/ready`,
Service et Ingress. L’image `ghcr.io/noliae-france/nolcore:main` est publiée
par GitHub Actions après chaque push sur `main`.

Créer les secrets hors dépôt, puis déployer :

```sh
kubectl -n nolcore create secret generic nolcore-secrets \
  --from-literal=postgres-password='mot-de-passe-fort' \
  --from-literal=session-secret="$(openssl rand -hex 32)" \
  --from-literal=NOLCORE_CHATGPT_TOKEN='' \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k deploy/k8s/base
kubectl -n nolcore rollout status statefulset/postgres
kubectl -n nolcore rollout status deployment/nolcore-api
```

Pour K3s, la même commande fonctionne ; remplacer l’Ingress par la classe
installée dans le cluster si nécessaire. Les tokens IA, SMTP et Discord sont
également fournis par `nolcore-secrets` ou par un Secret externe (External
Secrets/Vault), jamais par un fichier versionné.

## Démarrage rapide API

```sh
git clone https://github.com/Noliae-France/NolCore-API.git
cd NolCore-API
docker compose up --build
```

Le conteneur expose uniquement l’API HTTP sur `http://localhost:8080`.

Les valeurs par défaut de Compose sont destinées au développement local. En
production, fournir les secrets par l’environnement ou le gestionnaire de
secrets de la plateforme : ne jamais les commiter.

## API v1

### Utilisateur

```text
POST /v1/user/register
POST /v1/user/login
GET  /v1/user/me
POST /v1/user/resetpassword
POST /v1/user/me/changepassword
POST /v1/user/me/changemail
POST /v1/user/me/changename
```

La connexion renvoie un Bearer token et pose le cookie `nol_session`. Le cookie
est valable 24 heures et est invalidé en cas de changement d’IP ou d’email.

### IA multi-fournisseurs

```text
POST /v1/ia/:nameid/:modelia/:text
POST /v1/ia
```

Variables de configuration :

```env
NOLCORE_CLAUDE_URL=https://...
NOLCORE_CLAUDE_TOKEN=...
NOLCORE_CHATGPT_URL=https://...
NOLCORE_CHATGPT_TOKEN=...
NOLCORE_MISTRAL_URL=https://...
NOLCORE_MISTRAL_TOKEN=...
NOLCORE_GEMINI_URL=https://...
NOLCORE_GEMINI_TOKEN=...
```

### Recherche et crawler

```text
GET  /v1/search/text/:keyword
GET  /v1/search/img/:keyword
GET  /v1/search/ia/:keyword
POST /v1/crawler/visite/:url
GET  /v1/crawler/result/:url
```

Le crawler est exécuté par
[NolCore-Crawler](https://github.com/Noliae-France/NolCore-Crawler), qui
applique `robots.txt`. L’API conserve les résultats indexés dans PostgreSQL.

### Permissions, administration et Discord

```text
GET  /v1/perms
GET  /v1/admin/
POST /v1/smtp/:idsmtp/send
GET  /v1/smtp/:idsmtp/pool
DELETE /v1/smtp/:idsmtp/remove
GET  /v1/admin/user/
GET  /v1/admin/ia/
GET  /v1/admin/smtp/
GET  /v1/admin/crawler/
GET  /v1/admin/discord/
GET  /v1/discord/bot
POST /v1/discord/webhook
```

Configuration Discord : `NOLCORE_DISCORD_BOT_TOKEN`,
`NOLCORE_DISCORD_GUILD_ID` et `NOLCORE_DISCORD_WEBHOOK_URL`.

Les profils SMTP sont obligatoirement chiffrés : `465` utilise SMTPS implicite
et `587` utilise STARTTLS. Tout autre port est refusé par le worker SMTP.
Le mot de passe reste dans l’environnement indiqué par `secret_env` ; il n’est
jamais stocké dans PostgreSQL.

## Développement

Le workflow GitHub Actions compile l’image Docker avec le binaire Nolc public,
exécute un smoke test HTTP, démarre PostgreSQL, vérifie le schéma, puis teste
l’inscription, la connexion Bearer et la session cookie.

```sh
# Avec le compilateur Nolc installé
nolc check main.nol
```

## Sécurité

- Les secrets sont lus depuis l’environnement.
- Les mots de passe sont hachés avec Argon2id via libsodium.
- Les requêtes SQL sont paramétrées.
- Les cookies de session sont `HttpOnly`, `SameSite=Lax` et peuvent être `Secure`.
- Les recherches sont limitées et auditées.
- Les robots sont respectés avant toute visite.

NolCore est une base open source en évolution. Les règles de déploiement,
rotation de secrets, sauvegardes PostgreSQL, TLS, MFA et observabilité doivent
être définies pour chaque environnement de production.

## Licence

Voir [LICENSE](LICENSE).

## Documentation du projet

- [Politique de sécurité](SECURITY.md)
- [Guide de contribution](CONTRIBUTING.md)
- [Code de conduite](CODE_OF_CONDUCT.md)
- [Journal des changements](CHANGELOG.md)
