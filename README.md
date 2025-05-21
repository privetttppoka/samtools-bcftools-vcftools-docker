# Bioinformatics Tools Docker Image

Docker-образ с актуальными версиями специализированных биоинформатических программ:

- **samtools** v1.21
- **htslib** v1.21
- **libdeflate** v1.24
- **bcftools** v1.21
- **vcftools** v0.1.16

## 🔨 Сборка Docker-образа и его запуск в интерактивном режиме

```bash
docker build -t bioinfo-tools .
docker run -it bioinfo-tools bash
