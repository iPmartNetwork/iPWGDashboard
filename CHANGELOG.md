
# Changelog - iPWGDasboard Final Release

## 📅 Version: Final Complete (2025-05-10)

### 🚀 New Features & Enhancements:

1. **Environment Configuration:**
   - Migrated all sensitive configurations to `.env` using `python-dotenv`.

2. **Multi-User Authentication:**
   - Role-based user system (Admin & User).
   - Secure login/logout and password hashing.

3. **Client Quota & Expiration:**
   - Traffic limit and expiration date per client.
   - Automatic deactivation upon reaching limits.

4. **RESTful API:**
   - Secure API with token authentication.
   - Endpoints:
     - `POST /api/add_client`
     - `POST /api/remove_client`
     - `GET /api/clients`
     - `GET /api/status/<client_name>`

5. **Real-Time Monitoring Dashboard:**
   - Integrated Chart.js for live system and traffic monitoring.
   - API for system stats and client statuses.

6. **Backup & Restore:**
   - Manual and scheduled automated backups.
   - Restore functionality with integrity validation.
   - Backup API and download from the panel.

7. **QR Code Generation:**
   - Auto-generated QR Codes for client configurations.
   - Downloadable as PNG via panel and API.

8. **SSL & HTTPS Integration:**
   - Automatic Let's Encrypt SSL certificate generation.
   - Force HTTPS with NGINX reverse proxy support.

9. **Email & Telegram Notifications:**
   - Configurable SMTP and Telegram Bot notifications.
   - Events: Client addition/removal, quota/expiration alerts, backups.

10. **Final Stability & Performance Optimizations:**
    - Improved system resource management.
    - Enhanced UI/UX for a smoother experience.

✅ This marks the final, stable, and production-ready release of the iPWGDasboard Project!
