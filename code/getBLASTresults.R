library(ggplot2)
library(tidyverse)

blast <- 
	read.csv(file="rRNAs_barrnap_blast.results", sep="\t", header=TRUE)

extrTax <- function(df){
	df2 <- df %>%
	group_by(taxon) %>% 
	select(taxon, bitscore, identity, evalue) %>% 
	summarize(across(everything(), mean)) %>% 
	arrange(desc(bitscore))
return(df2)
}

species_table <- blast %>%
	nest(data=-seqID) %>%
	mutate(new = map(.x=data, ~extrTax(df=.), data = .x)) %>%
	unnest(new) %>% select(-data) %>% as.data.frame()

#genus_table <- blast %>% 
#	separate(taxon, c("Genus", "Species"), sep="_") %>%
#	dplyr::rename(.data = ., taxon = Genus) %>%
#	select(-Species) %>%
#	nest(data=-seqID) %>%
#	mutate(new = map(.x=data, ~extrTax(df=.), data = .x)) %>%
#	unnest(new) %>% select(-data) %>% as.data.frame()

write.table(species_table, file="rRNA_barrnap_blast.mean", sep="\t", quote=FALSE)
#write.table(genus_table, file="rRNA_blast_genus.results", sep="\t", quote=FALSE)
