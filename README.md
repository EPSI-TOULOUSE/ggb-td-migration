# TD PRATIQUE - Migration de données

**EPSI – ASRBD / STESE636**

Tests d'integration & Migration de donnees

- [Lucas Baduel](https://github.com/Lucas-test)
- [Quentin Grenier](https://github.com/Shalennn)
- [Valentin Gorrin](https://github.com/h33n0k)

## Étape 0 - Préparation de l'environnement local

1. Démarrer les services

```shell
docker compose up -d
```

2. S'assurer que les conteneurs soit démarré

```shell
docker ps
```

3. Injecter les données de base

```shell
chmod +x ./prepare.sh
./prepare.sh
```
