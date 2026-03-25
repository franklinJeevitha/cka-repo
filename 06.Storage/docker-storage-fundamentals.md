
# 💾 Docker Storage Fundamentals

Docker manages storage using two distinct methods: **Storage Drivers** (for the image layers) and **Mounts** (for persistent data).

## 1. The Layered File System (Copy-on-Write)
Docker images are built in layers. When you run a container, Docker adds a thin **Container Layer** (Writable Layer) on top of the read-only image layers.

* **Read-Only Layers:** Shared between all containers using that image.
* **Writable Layer:** Unique to each container. Any file changed or created exists only here.
* **Copy-on-Write (CoW):** If you modify an existing file from the image, Docker copies it from the read-only layer to the writable layer first.



---

## 2. Persistent Data: Volumes vs. Bind Mounts
Because the "Writable Layer" is deleted with the container, we use **Mounts** to store data on the host machine.

| Feature | **Volumes** (Recommended) | **Bind Mounts** |
| :--- | :--- | :--- |
| **Storage Location** | Managed by Docker (`/var/lib/docker/volumes`) | Anywhere on the Host OS (e.g., `/home/user/data`) |
| **Management** | Managed via Docker CLI | Managed by the Host OS users/processes |
| **Use Case** | Databases, logs, production data | Source code sharing, configuration files |
| **Isolation** | High (isolated from host processes) | Low (host processes can modify files) |



---

## 3. Storage Drivers
The storage driver is the engine that manages the image layers and the writable layer.
* **Common Driver:** `overlay2` (The current standard for Linux).
* **Legacy/Other Drivers:** `aufs`, `devicemapper`, `zfs`.
* **Selection:** Docker automatically chooses the best driver based on your Host OS. You can check yours with `docker info | grep Storage`.

---

## 4. Key Commands (Imperative)

```bash
# Create a managed volume
docker volume create my-db-data

# Run a container with a Volume
docker run -d --name db -v my-db-data:/var/lib/mysql mysql

# Run a container with a Bind Mount (Direct path)
docker run -d --name web -v /var/www/html:/usr/share/nginx/html nginx

# Inspect where the volume actually lives on your disk
docker volume inspect my-db-data
```

---

## 💡 Practical Engineering Tips

* Never store state (databases, user uploads) inside the container's writable layer. It will bloat the image and eventually lead to "Disk Pressure" errors on your host.
* **Volume Cleanup:** Over time, "dangling" volumes (volumes not attached to any container) will eat up your disk space. Use `docker volume prune` regularly to reclaim space.
* **Performance:** Bind mounts are generally faster for high-I/O development work, but Volumes are safer for production because they are abstracted from the host's specific file structure.

---
