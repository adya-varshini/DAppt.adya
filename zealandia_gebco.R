# =============================================================================
# Zealandia in R: mapping the hidden continent with GEBCO bathymetry
# Live-coding script for RStudio.  Run section by section: Ctrl+Enter (Win) / Cmd+Enter (Mac)
#
# BEFORE YOU START (do once, ~5 minutes):
#   1. Go to https://download.gebco.net and choose the latest GEBCO grid.
#   2. Download TILE A as GeoTIFF:  North -10, South -60, West 155, East 180
#   3. (Recommended) TILE B as GeoTIFF: North -10, South -60, West -180, East -165
#      (adds the Chatham Rise side of Zealandia, east of the date line)
#   4. Put the file(s) into the folder  data/  next to this script.
#   5. In RStudio: Session > Set Working Directory > To Source File Location
# =============================================================================

# ---- Make sure we work in the folder of this script (so the PNGs land next to the slides) ----
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  p <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(p)) setwd(dirname(p))
}
message("Working folder: ", getwd())

# ---- 0. Packages ------------------------------------------------------------
pkgs <- c("terra", "ggplot2", "scales", "dplyr")
new  <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(new)) install.packages(new)
library(terra)     # raster data (GEBCO is a raster)
library(ggplot2)   # map + plots
library(scales)    # colour scale helpers
library(dplyr)     # summaries

# =============================================================================
# PART 1: INTRODUCING THE DATA
# GEBCO = General Bathymetric Chart of the Oceans: ONE global grid of elevation.
# Every raster CELL has: a longitude (x), a latitude (y) and ONE value: elevation
# in metres relative to sea level. Positive = land, negative = sea floor.
# =============================================================================
files <- list.files("data", pattern = "\\.(tif|tiff|nc)$", ignore.case = TRUE, full.names = TRUE)
if (length(files) == 0) stop("No GEBCO file found in data/. See the steps at the top of this script.")

# Read each tile. Tiles east of the date line have negative longitudes (-180 to -165);
# we shift them by +360 so the Pacific is one continuous map (180 to 195 = 180 W to 165 W).
tiles <- lapply(files, function(f) {
  r <- rast(f)
  if (xmin(r) < 0) r <- shift(r, dx = 360)
  r
})
elev <- if (length(tiles) == 1) tiles[[1]] else do.call(merge, unname(tiles))
names(elev) <- "elev"

elev                       # look at it: dimensions, resolution, extent, CRS
res(elev)                  # cell size in degrees (GEBCO: 15 arc-seconds = 1/240 degree)
ncell(elev)                # number of cells (millions!)
minmax(elev)               # lowest and highest elevation in the region

# =============================================================================
# PART 2: LIVE R CODING: process the raster, build the map
# =============================================================================

# 2a. Too many cells to plot comfortably, so average blocks of 10 x 10 cells.
agg_fact <- 10
elev_s <- aggregate(elev, fact = agg_fact, fun = "mean", na.rm = TRUE)
res(elev_s)

# 2b. terra raster -> data frame (one row per cell) so ggplot2 can draw it
df <- as.data.frame(elev_s, xy = TRUE, na.rm = TRUE)
names(df) <- c("lon", "lat", "elev")
head(df)

# 2c. The colour scale: the most important design choice of the map.
#     Sea and land need different colours, and the break at 0 m must be visible.
br   <- c(-10500, -6000, -4000, -2000, -1000, -200, 0, 500, 1500, 3800)
cols <- c("#030b2e", "#0a2463", "#1b4f9c", "#2f80c9", "#5db0e6",
          "#b5e3f5", "#efe6b8", "#7fb069", "#a67c52", "#ffffff")
# br = elevation break points; cols = the colour at each break; ggplot blends in between.

# 2d. Simplified outline of Zealandia (after Mortimer et al., 2017); longitudes east of the
#     date line are written as 180 to 360 to match our raster.
zx <- c(160,164,169,172,175,179,183,185,184,178,167,165,167,166,162,159,160)
zy <- c(-22,-19,-20,-25,-31,-36,-41,-46,-50,-54,-55,-50,-45,-40,-35,-29,-22)
outline <- data.frame(lon = zx, lat = zy)

# 2e. Labels (only those inside our raster are drawn)
labs_df <- data.frame(
  lon  = c(173,   165.5,         160.5,          183.5,         170,               183.5,            159,           175),
  lat  = c(-41.5, -21.5,         -31,            -44.5,         -52,               -31,              -38,           -26),
  text = c("New Zealand", "New Caledonia", "Lord Howe Rise", "Chatham Rise", "Campbell Plateau",
           "Kermadec Trench", "Tasman Basin", "South Fiji Basin")
) |>
  filter(lon >= xmin(elev_s), lon <= xmax(elev_s), lat >= ymin(elev_s), lat <= ymax(elev_s))

# 2f. THE MAP
p_map <- ggplot(df, aes(lon, lat)) +
  geom_raster(aes(fill = elev)) +
  scale_fill_gradientn(colours = cols, values = rescale(br), limits = c(min(br), max(br)),
                       oob = squish, name = "Elevation (m)",
                       breaks = c(-6000, -4000, -2000, 0, 2000)) +
  geom_contour(aes(z = elev), breaks = -2500, colour = "white", linewidth = .25, alpha = .7) +
  geom_contour(aes(z = elev), breaks = 0, colour = "black", linewidth = .25) +
  geom_path(data = outline, aes(lon, lat), inherit.aes = FALSE,
            colour = "#0fffd0", linetype = "dashed", linewidth = .6) +
  geom_text(data = labs_df, aes(lon, lat, label = text), inherit.aes = FALSE,
            colour = "white", size = 3.2, fontface = "bold") +
  scale_x_continuous(labels = function(x) ifelse(x > 180, paste0(360 - x, "°W"), paste0(x, "°E")),
                     expand = c(0, 0)) +
  scale_y_continuous(labels = function(y) paste0(abs(y), "°S"), expand = c(0, 0)) +
  coord_quickmap() +
  labs(title = "Zealandia: the continent beneath the South Pacific",
       subtitle = "White line: 2,500 m depth. Dashed teal: simplified outline (after Mortimer et al., 2017)",
       x = NULL, y = NULL, caption = "Data: GEBCO bathymetric grid, aggregated to ~2.5 arc-minutes") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "right", panel.grid = element_blank())
p_map
ggsave("zealandia_map.png", p_map, width = 9, height = 7, dpi = 300)
message("Saved map to: ", normalizePath("zealandia_map.png"))

# =============================================================================
# PART 3: READING THE MAP: numbers behind the colours
# =============================================================================

# 3a. Which depth classes make up the (simplified) Zealandia area?
zpoly <- vect(cbind(id = 1, part = 1, x = zx, y = zy), type = "polygons", crs = "EPSG:4326")
cell_km2 <- cellSize(elev_s, unit = "km")           # area of each cell in km2
roi <- as.data.frame(c(mask(elev_s, zpoly), cell_km2), na.rm = TRUE)
names(roi) <- c("elev", "area_km2")
roi$class <- cut(roi$elev, breaks = c(-Inf, -5000, -2500, -200, 0, Inf),
                 labels = c("Deep basin (< -5,000 m)", "Slope (-5,000 to -2,500 m)",
                            "Platform (-2,500 to -200 m)", "Shelf (-200 to 0 m)", "Land (> 0 m)"))
summ <- roi |>
  group_by(class) |>
  summarise(area_mkm2 = sum(area_km2) / 1e6, .groups = "drop") |>
  mutate(share = area_mkm2 / sum(area_mkm2))
print(summ)
cat("\nArea covered by the data inside the outline:", round(sum(summ$area_mkm2), 2), "million km2\n")
cat("Share above sea level:", percent(summ$share[summ$class == "Land (> 0 m)"], accuracy = .1),
    " (published figure: about 6%, Mortimer et al., 2017)\n")
# NOTE: if you only downloaded tile A, the part of the outline east of 180 degrees is missing.

# 3b. Elevation distribution: why are there two humps?
set.seed(1)
samp <- df[sample(nrow(df), min(nrow(df), 2e5)), ]
p_hist <- ggplot(samp, aes(elev)) +
  geom_histogram(binwidth = 100, fill = "#2f80c9", colour = NA) +
  geom_vline(xintercept = 0, colour = "black") +
  geom_vline(xintercept = -2500, colour = "#0fffd0", linetype = "dashed") +
  labs(title = "Elevation distribution of the region",
       x = "Elevation (m)", y = "Number of cells") +
  theme_minimal(base_size = 12)
p_hist
ggsave("zealandia_hist.png", p_hist, width = 8, height = 4.5, dpi = 300)
message("Saved histogram to: ", normalizePath("zealandia_hist.png"))

# READING THE MAP
#  * Pale blue / shallow: the submerged continental platform (Lord Howe Rise, Campbell Plateau, Chatham Rise)
#  * Dark blue: deep ocean basins around it (Tasman Basin, South Fiji Basin) and trenches (Kermadec)
#  * Beige / green / brown: the few peaks above water (New Zealand, New Caledonia)
#  * Histogram: one hump of shallow cells (the platform) and one of deep cells (the ocean floor)
