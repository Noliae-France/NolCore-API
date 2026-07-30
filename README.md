<div align="center">

# ◈ NolCore API

### Gateway métier de Noliae, natif en Nolc

[![CI](https://github.com/Noliae-France/NolCore-API/actions/workflows/ci.yml/badge.svg)](https://github.com/Noliae-France/NolCore-API/actions/workflows/ci.yml)
[![Container](https://github.com/Noliae-France/NolCore-API/actions/workflows/container.yml/badge.svg)](https://github.com/Noliae-France/NolCore-API/actions/workflows/container.yml)
[![Runtime](https://img.shields.io/badge/runtime-Nolc-ff4d2e)](https://github.com/Noliae-France/nolc)
[![Licence MIT](https://img.shields.io/badge/licence-MIT-2ea44f)](LICENSE)

</div>

> **Statut de dépôt — migration.** Le dépôt canonique et publié pour NolCore
> est [NolCore](https://github.com/Noliae-France/NolCore). Cette séparation API
> est conservée pour la migration microservices et ne doit pas être déployée à
> la place du Core canonique tant que les contrats Auth, sessions et CI n’ont
> pas été synchronisés.

Pour les frontends et le déploiement, suivez la documentation du dépôt
[NolCore](https://github.com/Noliae-France/NolCore), qui centralise les
contrats actuellement publiés.

## Rôle du service

NolCore-API est l’API publique et la source de vérité métier : comptes,
authentification, sessions, permissions, administration, recherche,
conversations et SMTP. Il persiste ses données dans PostgreSQL.

Il ne contient volontairement ni crawler local ni token de fournisseur IA :

```text
Internet → NolCore-API → PostgreSQL
                         ├→ NolCore-IA       via NOLCORE_IA_URL
                         └→ NolCore-Crawler  via NOLCORE_CRAWLER_URL
```

Les services amont doivent rester privés dans Docker/Kubernetes. L’API est le
seul composant destiné à recevoir le trafic utilisateur.

## Capacités

| Domaine | Contenu |
|---|---|
| Users & Auth | Inscription, e-mail de vérification, login, profil et changement de compte |
| Sessions | Token Bearer et cookie signé, IP + e-mail + nonce, validité 24 h |
| Permissions | Rôles, permissions ciblées et contrôle administrateur |
| Recherche | Documents PostgreSQL et routes texte/image/IA |
| Conversations | Historique utilisateur et délégation vers NolCore-IA |
| Intégrations | SMTP sécurisé, bot Discord et webhook |
| Opérations | Santé, readiness, dépendances et administration |

## Lancer localement

```sh
git clone https://github.com/Noliae-France/NolCore-API.git
cd NolCore-API
export NOLIAE_SESSION_SECRET="change-me-with-at-least-32-characters"
docker compose up --build
```

Compose démarre PostgreSQL et consomme les images publiques de
`nolcore-ia` et `nolcore-crawler`. L’API répond sur `http://localhost:8080`.

```sh
curl http://localhost:8080/api/health
curl http://localhost:8080/api/ready
curl http://localhost:8080/api/dependencies
```

## Configuration

| Variable | Requise | Description |
|---|---:|---|
| `NOLIAE_SESSION_SECRET` | Oui | Secret de signature, 32 caractères minimum |
| `NOLCORE_DATABASE_URL` | Oui | Connexion PostgreSQL |
| `NOLCORE_IA_URL` | Oui | URL interne de NolCore-IA |
| `NOLCORE_CRAWLER_URL` | Oui | URL interne de NolCore-Crawler |
| `NOLCORE_DEFAULT_PROVIDER` | Non | Fournisseur de conversation par défaut |
| `NOLCORE_DEFAULT_MODEL` | Non | Modèle de conversation par défaut |
| `NOLCORE_VERIFICATION_SMTP_ID` | Non | Profil SMTP utilisé pour la vérification |
| `NOLCORE_PUBLIC_URL` | Non | Base URL dans les e-mails de vérification |
| `NOLCORE_DISCORD_*` | Non | Bot, guild et webhook Discord |

Les tokens Claude, ChatGPT, Mistral et Gemini sont configurés uniquement dans
[NolCore-IA](https://github.com/Noliae-France/NolCore-IA).

## API v1

| Groupe | Endpoints |
|---|---|
| Santé | `GET /api/health`, `/api/ready`, `/api/dependencies` |
| Auth | `POST /v1/user/register`, `/login`; `GET /v1/user/me`, `/verify` |
| Compte | `POST /v1/user/resetpassword`, `/me/changepassword`, `/me/changemail`, `/me/changename` |
| IA | `POST /v1/ia`, `POST /v1/ia/:nameid/:modelia/:text` |
| Recherche | `GET /v1/search/text/:keyword`, `/img/:keyword`, `/ia/:keyword` |
| Crawler | `POST /v1/crawler/visite/:url`, `GET /v1/crawler/result/:url` |
| Permissions | `GET /v1/perms` |
| Administration | `GET /v1/admin/user/`, `/ia/`, `/smtp/`, `/crawler/`, `/discord/` |
| SMTP | `POST /v1/smtp/:idsmtp/send`, `GET /pool`, `DELETE /remove` |
| Discord | `GET /v1/discord/bot`, `POST /v1/discord/webhook` |

Les routes protégées acceptent le Bearer token renvoyé par le login ou le
cookie `nol_session`. Les routes de recherche sont limitées en débit.

## SMTP

Les identifiants SMTP ne sont jamais stockés en base : le profil pointe vers
une variable d’environnement `secret_env`. Seuls les ports suivants sont
acceptés :

- `465` : SMTPS implicite ;
- `587` : STARTTLS obligatoire.

## Kubernetes / K3s

`deploy/k8s/base` déploie l’API et PostgreSQL. Renseignez les noms DNS internes
des services IA et crawler dans `NOLCORE_IA_URL` et `NOLCORE_CRAWLER_URL`.

```sh
kubectl -n nolcore create secret generic nolcore-secrets \
  --from-literal=postgres-password='mot-de-passe-fort' \
  --from-literal=session-secret="$(openssl rand -hex 32)"
kubectl apply -k deploy/k8s/base
```

## Développement et qualité

```sh
nolc check main.nol
```

La CI construit l’image Docker et effectue un smoke test. L’intégration complète
API + IA + Crawler est vérifiée dans le dépôt
[NolCore](https://github.com/Noliae-France/NolCore).

## Sécurité et licence

- Mots de passe hachés avec Argon2id/libsodium.
- SQL paramétré via libpq.
- Cookies `HttpOnly`, `SameSite=Lax` et `Secure` si configuré.
- Secrets injectés par environnement ou gestionnaire de secrets.

Voir [SECURITY.md](SECURITY.md), [CONTRIBUTING.md](CONTRIBUTING.md) et la
[licence MIT](LICENSE).
