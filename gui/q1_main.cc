//------------------------------------------------------------------------
//  LEVEL building - QUAKE 1 format
//------------------------------------------------------------------------
//
//  Oblige Level Maker (C) 2006-2008 Andrew Apted
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//------------------------------------------------------------------------

#include "headers.h"
#include "hdr_fltk.h"
#include "hdr_lua.h"
#include "hdr_ui.h"

#include "lib_file.h"
#include "lib_util.h"

#include "csg_poly.h"
#include "csg_doom.h"
#include "csg_quake.h"

#include "g_image.h"

#include "q1_main.h"
#include "q1_structs.h"

#include "main.h"


typedef std::vector<raw_dir_entry_t> directory_c;


static FILE *bsp_fp;

static qLump_c * bsp_directory[HEADER_LUMPS + 1];
// NB: the extra lump (+1) stores the Oblige information


static int write_errors_seen;
static int seek_errors_seen;


//------------------------------------------------------------------------
//  BSP-FILE OUTPUT
//------------------------------------------------------------------------

static u32_t AlignLen(u32_t len)
{
  return ((len + 3) & ~3);
}

static void BSP_RawSeek(u32_t pos)
{
  fflush(bsp_fp);

  if (fseek(bsp_fp, pos, SEEK_SET) < 0)
  {
    if (seek_errors_seen < 10)
    {
      LogPrintf("Failure seeking in bsp file! (offset %u)\n", pos);

      seek_errors_seen += 1;
    }
  }
}

static void BSP_RawWrite(const void *data, u32_t len)
{
  SYS_ASSERT(bsp_fp);

  if (1 != fwrite(data, len, 1, bsp_fp))
  {
    if (write_errors_seen < 10)
    {
      LogPrintf("Failure writing to bsp file! (%u bytes)\n", len);

      write_errors_seen += 1;
    }
  }
}

static void BSP_WriteLump(const char *name, const void *data, u32_t len)
{
  SYS_ASSERT(strlen(name) <= 8);

  // create entry for directory (written out later)
  raw_dir_entry_t entry;

  entry.start  = LE_U32((u32_t)ftell(bsp_fp));
  entry.length = LE_U32(len);

  strncpy(entry.name, name, 8);

  wad_dir.push_back(entry);

  if (len > 0)
  {
    BSP_RawWrite(data, len);

    // pad lumps to a multiple of four bytes
    u32_t padding = AlignLen(len) - len;

    SYS_ASSERT(0 <= padding && padding <= 3);

    if (padding > 0)
    {
      static u8_t zeros[4] = { 0,0,0,0 };

      BSP_RawWrite(zeros, padding);
    }
  }
}

static void BSP_WriteLump(const char *name, lump_c *lump)
{
  BSP_WriteLump(name, &(*lump)[0], lump->size());
}


qLump_c *Q1_NewLump(int entry)
{
  SYS_ASSERT(0 <= entry && entry < HEADER_LUMPS+1);

  if (bsp_directory[entry] != NULL)
    Main_FatalError("INTERNAL ERROR: Q1_NewLump: already created entry [%d]\n", entry);

  bsp_directory[entry] = new qLump_c;

  return bsp_directory[entry];
}


void Q1_Append(qLump_c *lump, const void *data, u32_t len)
{
  if (len > 0)
  {
    u32_t old_size = lump->size();
    u32_t new_size = old_size + len;

    lump->resize(new_size);

    memcpy(& (*lump)[old_size], data, len);
  }
}


void Q1_Printf(qLump_c *lump, const char *str, ...)
{
  static char buffer[MSG_BUF_LEN];

  va_list args;

  va_start(args, str);
  vsnprintf(buffer, MSG_BUF_LEN-1, str, args);
  va_end(args);

  buffer[MSG_BUF_LEN-2] = 0;

  // convert each newline into CR/LF pair

  char *pos = buffer;
  char *next;

  while (*pos)
  {
    next = strchr(pos, '\n');

    Q1_Append(lump, pos, next ? (next - pos) : strlen(pos));

    if (! next)
      break;

    Q1_Append(lump, "\r\n", 2);

    pos = next+1;
  }
}


void BSP_CreateInfoLump()
{
  // fake 16th lump in file
  lump_c *L = Q1_NewLump(HEADER_LUMPS);

  Q1_Printf(L, "\n\n\n\n");

  Q1_Printf(L, "-- Map created by OBLIGE %s\n", OBLIGE_VERSION);
  Q1_Printf(L, "-- " OBLIGE_TITLE " (C) 2006-2008 Andrew Apted\n");
  Q1_Printf(L, "-- http://oblige.sourceforge.net/\n");
  Q1_Printf(L, "\n");

 
  Q1_Printf(L, "-- Game Settings --\n");
  Q1_Printf(L, "%s\n", main_win->game_box->GetAllValues());

  Q1_Printf(L, "-- Level Architecture --\n");
  Q1_Printf(L, "%s\n", main_win->level_box->GetAllValues());

  Q1_Printf(L, "-- Playing Style --\n");
  Q1_Printf(L, "%s\n", main_win->play_box->GetAllValues());

//Q1_Printf(L, "-- Custom Mods --\n");
//Q1_Printf(L, "%s\n", main_win->mod_box->GetAllValues());

//Q1_Printf(L, "-- Custom Options --\n");
//Q1_Printf(L, "%s\n", main_win->option_box->GetAllValues());

  Q1_Printf(L, "\n\n\n\n\n\n");

  // terminate lump with ^Z and a NUL character
  static const byte terminator[2] = { 26, 0 };

  Q1_Append(L, terminator, 2);
}


//------------------------------------------------------------------------

static int begin_level(lua_State *L)
{

  return 0;
}

static int end_level(lua_State *L)
{
//  CSG2_TestQuake();

  CSG2_WriteDoom();

  CSG2_EndLevel();


  SYS_ASSERT(level_name);

  for (int i = 0; i < HEADER_LUMPS+1; i++)
  {
    BSP_WriteLump(i);
  }

  // FIXME !!!!  free bsp_directory[] entries

  return 0;
}


//------------------------------------------------------------------------

void Quake1_Init(void)
{

}

bool Quake1_Start(void)
{

  write_errors_seen = 0;
  seek_errors_seen  = 0;

  wad_dir.clear();
  wad_hexen = is_hexen;

  // dummy header
  raw_wad_header_t header;

  strncpy(header.type, "XWAD", 4);

  header.dir_start   = 0;
  header.num_entries = 0;

  BSP_RawWrite(&header, sizeof(header));

  BSP_CreateInfoLump();

  return true; //OK
}


bool Quake1_Finish(void)
{
  WAD_WritePatches();
 
  // compute *real* header 
  raw_wad_header_t header;

  strncpy(header.type, "PWAD", 4);

  header.dir_start   = LE_U32((u32_t)ftell(bsp_fp));
  header.num_entries = LE_U32(wad_dir.size());


  // WRITE DIRECTORY
  directory_c::iterator D;

  for (D = wad_dir.begin(); D != wad_dir.end(); D++)
  {
    BSP_RawWrite(& *D, sizeof(raw_dir_entry_t));
  }

  // FSEEK, WRITE HEADER

  BSP_RawSeek(0);
  BSP_RawWrite(&header, sizeof(header));

  fclose(bsp_fp);
  bsp_fp = NULL;

  return (write_errors_seen == 0) && (seek_errors_seen == 0);
}


static void Quake1_Backup(const char *filename)
{
  if (FileExists(filename))
  {
    LogPrintf("Backing up existing file: %s\n", filename);

    char *backup_name = ReplaceExtension(filename, "bak");

    if (! FileCopy(filename, backup_name))
      LogPrintf("WARNING: unable to create backup: %s\n", backup_name);

    StringFree(backup_name);
  }
}

bool Quake1_Nodes(const char *target_file)
{
  DebugPrintf("TARGET FILENAME: [%s]\n", target_file);

  Quake1_Backup(target_file);

  // ... TODO
}


void Quake1_Tidy(void)
{
}

//--- editor settings ---
// vi:ts=2:sw=2:expandtab
