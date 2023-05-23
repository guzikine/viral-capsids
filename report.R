library(data.table)
library(ggplot2)

#============================
# Processing volume data
#============================
volumes <- read.delim("./capsid_volumes.tab", sep = "\t", header = FALSE)
colnames(volumes) <- c("entry_id", "volume")
volumes$volume <- as.numeric(volumes$volume)
volumes$volume <- volumes$volume / 1000000
volumes$volume <- sprintf("%.2f", volumes$volume)

separate_outliers <- function(data, column, column_to_leave) {
  q1 <- as.numeric(quantile(as.numeric(data[[column]]), 0.25))
  q3 <- as.numeric(quantile(as.numeric(data[[column]]), 0.75))
  iqr <- q3 - q1
  
  lower_bound <- q1 - 3 * iqr
  upper_bound <- q3 + 3 * iqr
  
  num_rows <- nrow(data)
  
  outlier_entry_id <- c()
  outlier_volume <- c()
  
  for (i in 1:num_rows) {
    x <- as.numeric(data[i, column])
    if (x < lower_bound || x > upper_bound) {
      outlier_entry_id <- append(outlier_entry_id, data[i, column_to_leave])
      outlier_volume <- append(outlier_volume, data[i, column])
    }
  }
  
  outlier_list <- list(data.frame(entry_id = outlier_entry_id, volume = outlier_volume))
  return(outlier_list)
}

outliers <- separate_outliers(volumes, "volume", "entry_id")[[1]]
outliers <- outliers[order(as.numeric(outliers$volume), decreasing = TRUE), ]

# Volumes without four digit numbers
ids_no_four_digits <- outliers[1:17, 1]
without_four_digits <- volumes[!(volumes$entry_id %in% ids_no_four_digits), ]
without_four_digits$volume <- as.numeric(without_four_digits$volume)

ggplot(without_four_digits, aes(x = volume)) +
  geom_histogram(aes(y=..density..), color="black", fill="white") +
  geom_density(alpha=.2, fill="#FF6666") +
  xlab("Volume (\u212B x 10^6)") +
  ylab("Density") + 
  theme(axis.title = element_text(size = 14))

# Volumes without IQR*3
ids_to_remove <- outliers$entry_id
volumes_iqr <- volumes[!(volumes$entry_id %in% ids_to_remove), ]
volumes_iqr$volume <- as.numeric(volumes_iqr$volume)

ggplot(volumes_iqr, aes(x = volume)) +
  geom_histogram(aes(y=..density..), color="black", fill="white") +
  geom_density(alpha=.2, fill="#FF6666") +
  xlab("Volume (\u212B x 10^6)") +
  ylab("Density") + 
  theme(axis.title = element_text(size = 14))

#============================
# Processing genome data
#============================
genomes <- read.delim("./REST/virus_species.tab", sep = "\t", header = FALSE)
colnames(genomes) <- c("entry_id", "species", "genome_length")
genomes <- genomes[complete.cases(genomes), ]

genome_outliers <- separate_outliers(genomes, "genome_length", "entry_id")[[1]]
genome_outliers <- genome_outliers[order((genome_outliers$volume), decreasing = TRUE), ]

# Genomes without initial 5Mbp or more
ids_initial_to_remove <- genome_outliers[1:12, 1]
genome_without_initial <- genomes[!(genomes$entry_id %in% ids_initial_to_remove), ]
genome_without_initial$genome_length <- as.numeric(genome_without_initial$genome_length)

ggplot(genome_without_initial, aes(x = genome_length)) + 
  geom_histogram(color="black", fill="white") +
  xlab("Genome length (bp)") +
  ylab("Count") + 
  theme(axis.title = element_text(size = 14))

# Genomes without IQR*3
genome_ids_to_remove <- genome_outliers$entry_id
genomes_iqr <- genomes[!(genomes$entry_id %in% genome_ids_to_remove), ]
genomes_iqr$genome_length <- as.numeric(genomes_iqr$genome_length)

ggplot(genomes_iqr, aes(x = genome_length)) + 
  geom_histogram(aes(y=..density..), color="black", fill="white") +
  geom_density(alpha=.2, fill="#FF6666") +
  xlab("Genome length (bp)") +
  ylab("Count") + 
  theme(axis.title = element_text(size = 14))

#============================
# Genomes and volumes
#============================
merged_data <- merged_df <- merge(volumes_iqr, genomes_iqr, by = "entry_id")
merged_data$volume <- as.numeric(merged_data$volume)
merged_data$genome_length <- as.numeric(merged_data$genome_length)

shapiro.test(merged_data$volume)
shapiro.test(merged_data$genome_length)

ggplot(merged_data, aes(x = volume, y = genome_length)) +
  geom_point() +
  xlab("Volume (\u212B x 10^6)") +
  ylab("Genome length (bp)") + 
  theme(axis.title = element_text(size = 14))

correlation <- cor(merged_data$volume, merged_data$genome_length)
print(correlation)


