# StatsLife

A Vue 3 application to track explored areas of the world using 5km x 5km tiles.

## Features

- Interactive map to mark explored 5km x 5km areas
- Automatic clustering of connected tiles
- Achievement squares (2x2, 3x3, etc.) detection
- Simple click-to-add tile interface

## Setup

1. Clone the repository
2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the root directory with your Supabase credentials:
```
VITE_SUPABASE_URL=your_supabase_url_here
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

4. Run the SQL migrations in your Supabase database:
   - Copy the contents of `supabase/migrations/20240318_initial_schema.sql`
   - Run it in your Supabase SQL editor

5. Start the development server:
```bash
npm run dev
```

## Usage

1. Open the application in your browser
2. Click the "Add Tile" button to enter tile creation mode
3. Click anywhere on the map to add a 5km x 5km tile
4. Tiles will automatically form clusters when they touch
5. Squares will be automatically detected when tiles form complete squares

## Database Schema

The application uses three main tables in the `statslife` schema:

1. `tiles` - Stores individual 5km x 5km tiles
2. `clusters` - Groups of connected tiles
3. `squares` - Achievement squares of various sizes

## Contributing

Feel free to open issues or submit pull requests for any improvements.

## License

MIT
# statslife
