# mneme-deploy

Run the whole Mneme product on your own Linux machine: start it, study, stop it.
Everything is built locally from the service repositories and reachable only from
this computer (`127.0.0.1`).

| Service    | URL                     |
|------------|-------------------------|
| mneme-web  | http://localhost:8000   |
| mneme-core | http://localhost:8080   |
| mneme-auth | http://localhost:8081   |

Memory: about 1–1.2 GB while running, nothing when stopped.

## 1. Install Docker (once)

Ubuntu / Debian:

```sh
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"   # then log out and back in
docker compose version            # must print v2.x
```

Also needed: `git`, `openssl`, `curl` (usually preinstalled).

## 2. Clone the four repositories side by side (once)

```sh
mkdir -p ~/mneme && cd ~/mneme
git clone <mneme-core repo URL>
git clone <mneme-auth repo URL>
git clone <mneme-web repo URL>
git clone <mneme-deploy repo URL>
```

The layout must be:

```
~/mneme/
├── mneme-core/
├── mneme-auth/
├── mneme-web/
└── mneme-deploy/
```

## 3. Daily use

```sh
~/mneme/mneme-deploy/mneme-start   # starts everything, opens the browser
~/mneme/mneme-deploy/mneme-stop    # stops everything, keeps your data
```

The first `mneme-start` takes 5–10 minutes: it generates the JWT keypair (`keys/`) and the
database passwords (`.env`) and builds all images. Later starts take 20–40 seconds,
the time the two Spring Boot services need to boot.

### Menu icon (optional)

```sh
cd ~/mneme/mneme-deploy
sed "s|__DIR__|$PWD|" mneme.desktop > ~/.local/share/applications/mneme.desktop
```

"Mneme" now appears in the application menu.

## Updating to new code

```sh
cd ~/mneme/mneme-core && git pull     # and/or mneme-auth, mneme-web
~/mneme/mneme-deploy/mneme-start --build
```

## Your data

All cards and accounts live in the Docker volume `mneme_pgdata`.

- `mneme-stop` and `docker compose down` keep it.
- **`docker compose down -v` deletes it permanently.** Don't use `-v`.

Back up:

```sh
cd ~/mneme/mneme-deploy
docker compose exec -T postgres pg_dumpall -U postgres > mneme-backup-$(date +%F).sql
```

Restore into a fresh volume. Start only postgres, so the services don't create empty
tables first. "already exists" errors for the roles and databases are expected:

```sh
docker compose up -d postgres
docker compose exec -T postgres psql -U postgres < mneme-backup-YYYY-MM-DD.sql
./mneme-start
```

`keys/` and `.env` are secrets generated on this machine and are git-ignored. Keep
`.env` with your backups: the database passwords are stored in it. If `keys/` is lost,
`mneme-start` makes a new keypair and you just log in again.

## Troubleshooting

```sh
cd ~/mneme/mneme-deploy
docker compose ps                 # what is running
docker compose logs mneme-core    # or mneme-auth, mneme-web, postgres
```

- **Port already in use**: change `WEB_PORT` in `.env`, then `./mneme-start --build`.
  Ports 8080/8081 are fixed because the web bundle has them baked in.
- **Login works but the session is lost on reload**: use `http://localhost:8000`, not
  `127.0.0.1:8000`. The refresh cookie and CORS are set up for `localhost`.
