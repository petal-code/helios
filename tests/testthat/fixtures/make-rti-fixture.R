# Builds rti-06075.zip, a hand-made extract in the 2010 RTI synthetic population format.
# The people are made up. Run from this directory with `Rscript make-rti-fixture.R`.

prefix <- "2010_ver1_06075_"
dir <- tempfile("rti-fixture-")
dir.create(dir)

school_ids <- c(450000001, 450000002, 450000003, 450000004, 450000005)
work_ids <- c(510000001, 510000002, 510000003, 510000004, 510000005)

# One row per household: its members' ages, school ids and work ids (NA = none), and
# optionally its location (default 37.75, -122.45) and census block group (default
# 060750101001).
# Schools 1 and 2 are public, 3 and 5 private, and 4 is a private catch-all with no location.
households <- list(
  list(age = c(40, 38, 10, 7), school = c(NA, NA, 1, 1), work = c(1, 2, NA, NA)),
  list(age = c(72), school = NA, work = NA),
  list(age = c(17, 45), school = c(2, NA), work = c(3, 3)), # the 17-year-old has both ids
  list(age = c(30, 29), school = c(NA, NA), work = c(4, NA)),
  list(age = c(81, 70), school = c(NA, NA), work = c(NA, 5)),
  list(age = c(50, 48, 18, 16, 14, 12, 9, 6, 4, 1, 0, 75), # a large household
       school = c(NA, NA, NA, 2, 2, 4, 4, 3, 3, NA, NA, NA), # 12 and 9 in the catch-all
       work = c(2, NA, 5, NA, NA, NA, NA, NA, NA, NA, NA, NA),
       latitude = 37.70, longitude = -122.50),
  list(age = c(25), school = NA, work = 1),
  list(age = c(33, 35, 3), school = c(NA, NA, 4), work = c(4, 4, NA), # 3 in the catch-all
       latitude = 37.70, longitude = -122.50, block_group = "060750100001")
)

people <- do.call(rbind, lapply(seq_along(households), function(h) {
  x <- households[[h]]
  n <- length(x$age)
  data.frame(
    sp_hh_id = 86000000 + h,
    serialno = 2007000000000 + h,
    stcotrbg = if (is.null(x$block_group)) "060750101001" else x$block_group,
    age = x$age,
    sex = rep_len(c(1, 2), n),
    race = 1,
    sporder = seq_len(n),
    relate = c(0, rep(2, n - 1)),
    sp_school_id = school_ids[as.integer(x$school)],
    sp_work_id = work_ids[as.integer(x$work)]
  )
}))
people <- cbind(sp_id = 164000000 + seq_len(nrow(people)), people)

# School 5 is nearer the catch-all students' homes than school 3, but has no preschool
schools <- data.frame(
  sp_id = school_ids,
  name = c("SCHOOL A", "SCHOOL B", "SCHOOL C", "CATCH-ALL ACADEMY", "SCHOOL E"),
  stabbr = c("CA", "CA", "CA", "ME", "CA"), address = "", city = "",
  county = c("SAN FRANCISCO", "SAN FRANCISCO", "SAN FRANCISCO", "LINCOLN", "SAN FRANCISCO"),
  zipcode = "", zip4 = "",
  nces_id = c("060000000001", "060000000002", "00000003", "A9303308", "00000005"),
  total = c(350, 1200, 40, 1985724, 1),
  prek = c(0, 0, 10, 890009, 0), kinder = c(50, 0, 5, 211491, 0),
  gr01_gr12 = c(300, 1200, 25, 884224, 1), ungraded = "",
  latitude = c(37.75, 37.76, 37.77, 0, 37.71), longitude = c(-122.45, -122.44, -122.43, 0, -122.51),
  source = c("NCES", "NCES", "schoolinformation.com", "schoolinformation.com", "schoolinformation.com"),
  stco = c("06075", "06075", "06075", "23015", "06075")
)

workplaces <- data.frame(
  sp_id = work_ids,
  workers = c(12, 3, 250, 40, 5),
  latitude = c(37.78, 37.79, 41.88, 37.80, 37.81),
  longitude = c(-122.41, -122.40, -87.63, -122.39, -122.38)
)

synth_households <- data.frame(
  sp_id = unique(people$sp_hh_id),
  serialno = unique(people$serialno),
  stcotrbg = "060750101001",
  hh_race = 1, hh_income = 50000,
  hh_size = lengths(lapply(households, `[[`, "age")),
  hh_age = 40,
  latitude = vapply(households, function(x) if (is.null(x$latitude)) 37.75 else x$latitude, numeric(1)),
  longitude = vapply(households, function(x) if (is.null(x$longitude)) -122.45 else x$longitude, numeric(1))
)

pums_p <- data.frame(
  serialno = people$serialno, rt = "P", sporder = people$sporder, puma = 2201, st = 6,
  agep = people$age,
  sch = ifelse(is.na(people$sp_school_id), 1, ifelse(people$sp_school_id %in% school_ids[3:5], 3, 2)),
  # PUMS grade codes: 1 preschool, 2 kindergarten, 3 grades 1-4, 4 grades 5-8, 5 grades 9-12
  schg = ifelse(is.na(people$sp_school_id), NA, cut(people$age, c(-1, 4, 5, 9, 13, 18), labels = FALSE))
)

write_rti <- function(x, name) {
  utils::write.csv(x, file.path(dir, paste0(prefix, name, ".txt")), row.names = FALSE, na = "")
}
write_rti(people, "synth_people")
write_rti(schools, "schools")
write_rti(workplaces, "workplaces")
write_rti(synth_households, "synth_households")
write_rti(pums_p, "pums_p")
writeLines("2010 U.S. Synthesized Population Dataset (test fixture)", file.path(dir, paste0(prefix, "metadata.txt")))

out <- file.path(getwd(), "rti-06075.zip")
unlink(out)
withr::with_dir(dir, utils::zip(out, list.files(), flags = "-q -X"))
