ZEALANDIA PRESENTATION: everything you need (read top to bottom)

FILES
  zealandia_slides.qmd    the slides (globe, zoom, code, QR on the last slide)
  zealandia_handout.qmd   the APA handout (A4, BibTeX, affidavit, checklist)
  overview.qmd            page behind QR 1: what you teach + the R basics
  exercise.qmd            page behind QR 2: the beginner exercise (R in the browser)
  zealandia_gebco.R       run in RStudio to make the two map pictures for the slides
  qr_codes.html           open in a browser to create + download QR 1 and QR 2 as images
  _quarto.yml             ONE line to edit: site_url (your GitHub Pages address)
  references.bib, apa.csl bibliography + APA style     globe.html: the globe (do not edit)

1. DATA (once). Download GEBCO GeoTIFF tiles at https://download.gebco.net into data/
     Tile A: N -10, S -60, W 155, E 180    Tile B: N -10, S -60, W -180, E -165
   Open zealandia_gebco.R in RStudio and run it (creates zealandia_map.png + zealandia_hist.png).
2. YOUR ADDRESS. In _quarto.yml set site_url to  https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/
3. RENDER. You need Quarto 1.9 or newer (the apaquarto extension requires it; update from quarto.org).
   In RStudio Terminal:  quarto render
   First time only: quarto install tinytex  and  install.packages(c("terra","ggplot2","scales","dplyr","qrcode","yaml","knitr","maps"))
   Result is in docs/ (HTML files + handout PDF).
4. PUBLISH. Upload the project to GitHub. Settings > Pages > Branch main, folder /docs.
   Test: https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/overview.html must open.
5. QR CODES. Open qr_codes.html, type username + repository, download both PNGs.
   QR 1 (show at the start) = overview page. QR 2 (last slide) = exercise page.
6. PRESENT. Open docs/zealandia_slides.html in CHROME (not the RStudio viewer), press F for fullscreen.
   Wait 2 seconds on slide 1: the globe zooms in to the campus. Arrow keys move on.
7. SUBMIT (from your prof's checklist): .qmd + .html + .pdf of slides AND handout on ILIAS;
   pull request to hubchev/make_a_pull_request; fill in the affidavit date.
   Slides PDF: open docs/zealandia_slides.html in Chrome, add  ?print-pdf  at the end of the address, press Enter,
   WAIT ~10 seconds until every page shows the globe, then Ctrl+P > Destination: Save as PDF > Margins: None >
   tick "Background graphics" > Save. (Each page is one slide, with its own globe picture.)
