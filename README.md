# Bioinformatics Tools Docker Image

Docker-образ с актуальными версиями специализированных биоинформатических программ:

- **samtools** v1.21
- **htslib** v1.21
- **libdeflate** v1.24
- **bcftools** v1.21
- **vcftools** v0.1.16

## Сборка Docker-образа и его запуск в интерактивном режиме

```bash
docker build -t bioinfo-tools .
docker run -it bioinfo-tools bash
```

## Запуск скрипта через командную строку

```bash
python VCF_creator.py   --input FP_SNPs_10k_GB38_twoAllelsFormat.tsv   --output FP_SNPs_REF_ALT.tsv   --ref_dir ref/GRCh38.d1.vd1_mainChr/sepChrs/   --log snp_converter.log
```
