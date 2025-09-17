library(qrcode)

code <- qr_code("https://github.com/andrewheiss/election-desk", ecl = "M")

generate_svg(code, filename = "R/qr_code.svg", show = FALSE)

ragg::agg_png("R/qr_code.png", width = 1000, height = 1000, res = 300)
plot(code)
invisible(dev.off())
