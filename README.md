# Friends & Family Details — GitHub Pages + Supabase

A teal-and-pink mobile-friendly address-book form where each person receives a private edit link.

## Why Supabase?
GitHub Pages is static and cannot save form edits by itself. Supabase stores the data while GitHub Pages hosts the website.

## Privacy model
- The `people` table has Row Level Security enabled.
- Anonymous visitors cannot directly read the table.
- Each person gets a random `edit_token`.
- The page only loads/updates a row when the private token matches.
- Treat each edit link like a password.
- Never put a Supabase `service_role` key in this repository.

## Setup

1. Create a free Supabase project.
2. Open **SQL Editor** and run `schema.sql`.
3. In Supabase, go to **Project Settings → API** and copy:
   - Project URL
   - public / anon key
4. Put those values into `config.js`.
5. Create a GitHub repository and upload all files in this folder.
6. In GitHub: **Settings → Pages → Deploy from branch → main / root**.
7. Once GitHub Pages is live, run this in Supabase SQL Editor:

```sql
select
  name,
  'https://YOUR-GITHUB-USERNAME.github.io/YOUR-REPO/edit.html?token=' || edit_token
    as private_edit_link
from public.people
order by extract(month from birthday), extract(day from birthday);
```

8. Replace the example GitHub URL with your real Pages URL and send each person only their own link.

## Included fields
- Name
- Birthday
- Address
- Phone
- Email
- Favourite flower
- Favourite treat
- Favourite drink
- Hobbies
- Likes
- Dislikes

Name and birthday are read-only on the public form, while the other fields can be updated.

## Important
This app stores personal information. Keep the repository code public if you want, but **never** commit real edit tokens or export the database into GitHub.
