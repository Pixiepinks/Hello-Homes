

# 🚀 Laravel + Flutter Deployment Guide (Railway & GitHub)

මෙමඟින් Local (SQLite) මඟින් ධාවනය වන ප්‍රොජෙක්ට් එක සජීවීව (Live Server) MySQL ඩේටාබේස් එකක් සමඟ Railway වෙත Deploy කරන ආකාරය පියවරෙන් පියවර දක්වා ඇත.

---

## 📌 පූර්ව සූදානම (Important Reminders)

* **Local DB:** දැනට Local පරිගණකයේ වැඩ කරන්නේ **SQLite** (`database.sqlite`) මඟිනි.
* **Live DB:** Railway මතදී අපි **MySQL** ඩේටාබේස් එකක් වෙනම සාදා භාවිත කළ යුතුය (මන්ද Railway filesystem එක තාවකාලික/ephemeral බැවිනි).
* **Security:** ඔබේ `.env` ෆයිල් එක කිසිවිටකත් GitHub වෙත Push නොකරන්න.

---

## 📂 පියවර 1: GitHub වෙත Code එක Upload කිරීම

වඩාත්ම පහසු සහ නිවැරදි ක්‍රමය වන්නේ `backend` සහ `frontend` ෆෝල්ඩර දෙක **වෙන වෙනම GitHub Repositories දෙකක්** ලෙස Upload කිරීමයි.

*(එකම Repository එකක් ඇතුළේ Folder දෙකම දාන්නේ නම්, Railway Settings වල **Root Directory** එක `/backend` ලෙස වෙනස් කිරීමට මතක තබාගන්න).*

1. GitHub එකෙහි අලුතින් Private/Public Repository එකක් සාදන්න (උදා: `my-laravel-backend`).
2. ඔබේ local `backend` ෆෝල්ඩරය terminal එකෙන් open කර GitHub වෙත push කරන්න:
```bash
git init
git add .
git commit -m "Initial backend commit"
git remote add origin <your-github-repo-url>
git branch -M main
git push -u origin main

```



```

---

## 🗄️ පියවර 2: Railway මත MySQL Database එකක් සෑදීම
ප්‍රොජෙක්ට් එක රන් වීමට Live Database එකක් අවශ්‍ය බැවින් මුලින්ම එය සකසා ගනිමු.

1. **Railway Dashboard** එකට ලොග් වන්න (`railway.app`).
2. **New Project** ක්ලික් කර, එතැනින් **Provision MySQL** තෝරන්න.
3. සුළු මොහොතකින් Railway විසින් ඔබට සජීවී MySQL Database එකක් සාදා දෙනු ඇත.

---

## 💻 පියවර 3: Backend එක Railway වෙත Deploy කිරීම සහ Config කිරීම
1. Railway Dashboard එකෙහි **New** -> **GitHub Repo** තෝරා, ඔබේ Laravel Backend repository එක එකතු කරන්න.
2. Deployment එක ආරම්භ වනු ඇත. එය සම්පූර්ණ වීමට පෙර **Environment Variables** සැකසිය යුතුය.
3. ඔබේ Railway Laravel App එක උඩ ක්ලික් කර **Variables** ටැබ් එකට යන්න.
4. එහි **New Variable** ක්ලික් කර පහත විස්තර එකින් එක ඇතුළත් කරන්න (Local `.env` එක වෙනුවට):

   * `APP_ENV` = `production`
   * `APP_KEY` = *(ඔබේ local .env ෆයිල් එකෙහි ඇති දිගු key එක)*
   * `APP_DEBUG` = `false`
   * `APP_URL` = *(Railway මඟින් මේ Backend ඇප් එකට ලබාදෙන Public URL එක)*
   * `DB_CONNECTION` = `mysql`
   * **Database Credentials (Reference Variables සරලව ඇතුළත් කරන්න):**
     * `DB_HOST` = `${{MySQL.MYSQLHOST}}`
     * `DB_PORT` = `${{MySQL.MYSQLPORT}}`
     * `DB_DATABASE` = `${{MySQL.MYSQLDATABASE}}`
     * `DB_USERNAME` = `${{MySQL.MYSQLUSER}}`
     * `DB_PASSWORD` = `${{MySQL.MYSQLPASSWORD}}`
   * *(මීට අමතරව ඔබේ local .env එකෙහි ඇති PHP Mailer/SMTP details ද මෙතැනට ඇතුළත් කරන්න).*

5. **Database Migrations Run කිරීම:** Railway හි **Settings** ටැබ් එකට ගොස් **Build / Deploy** යටතේ ඇති Custom Deploy Command එකක් ලෙස හෝ Laravel configuration එකට අනුව `php artisan migrate --force` ක්‍රියාත්මක වන බව තහවුරු කරගන්න.

---

## 📱 පියවර 4: Flutter Frontend එක Deploy කිරීම
1. **API URL එක වෙනස් කිරීම:** Flutter කෝඩ් එකෙහි ඇති Local API Base URL එක (උදා: `http://localhost:8000/api`), Railway මඟින් Backend එකට ලැබුණු නව **Production URL** එකට වෙනස් කරන්න.
2. Flutter ෆෝල්ඩරය Terminal එකෙන් open කර Web App එක build කරන්න:
   ```bash
   flutter build web

```

3. මෙමඟින් `frontend/build/web` නමින් ෆෝල්ඩරයක් සෑදේ. එහි ඇති static ෆයිල් ටික Railway, Vercel, හෝ Netlify වෙත සාමාන්‍ය Static Web අඩවියක් ලෙස පහසුවෙන් Deploy කරන්න.

---

## 🔄 පියවර 5: මෘදුකාංගය අප්ඩේට් (Update) කිරීම සහ ඩේටා කළමනාකරණය

### කෝඩ් එක අප්ඩේට් කරද්දී Live DB එකේ Data මැකෙයිද?

* **නැත.** ඔබ කෝඩ් එක වෙනස් කර GitHub push කර Railway අප්ඩේට් (Redeploy) කළද, **MySQL Database එකෙහි ඇති දත්ත වලට කිසිදු බලපෑමක් නොවේ.** ඒවා සුරක්ෂිතව පවතී.
* කෝඩ් එකෙහි ඩේටාබේස් ටේබල් වල අලුත් වෙනස්කම් (Migrations) තිබේ නම්, Deploy වෙද්දී `php artisan migrate --force` මඟින් පැරණි දත්ත මකන්නේ නැතිව අලුත් වෙනස්කම් පමණක් එකතු කරයි.

### 💡 Live DB එකේ Data Import / Export (Backup) කරගන්නේ කොහොමද?

ලයිව් සර්වර් එකේ දත්ත බැකප් කරගැනීමට හෝ පරිගණකයේ ඇති දත්ත ලයිව් සර්වර් එකට දැමීමට පහසුම ක්‍රමය:

1. **TablePlus / HeidiSQL Tool එකක් භාවිතය:**
* Railway MySQL Service එකේ **Connect** ටැබ් එකට ගොස් **Public Connection URL** එක copy කරගන්න.
* එය TablePlus වැනි Tool එකකට ඇතුළත් කර Live Database එකට සාර්ථකව Connect වන්න.
* එතැන් සිට ඔබට අවශ්‍ය ඕනෑම වෙලාවක මුළු Database එකම **Export (.sql file)** කර ගැනීමට හෝ ඔබේ ළඟ ඇති ඩේටා **Import** කර ගැනීමට හැකියාව ලැබේ.
