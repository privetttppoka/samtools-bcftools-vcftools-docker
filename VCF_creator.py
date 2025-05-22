#!/usr/bin/env python3

import argparse
import logging
import os
import sys
from datetime import datetime
import pysam

def setup_logging(log_file):
    logging.basicConfig(
        filename=log_file,
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

def parse_args():
    parser = argparse.ArgumentParser(
        description="Преобразование файла SNP в формат с определением референсного аллеля"
    )
    parser.add_argument("--input", required=True, help="Путь к входному TSV-файлу с аллелями")
    parser.add_argument("--output", required=True, help="Путь к выходному TSV-файлу с REF и ALT")
    parser.add_argument("--ref_dir", required=True, help="Путь к директории с chr*.fa файлами референсного генома")
    parser.add_argument("--log", default="snp_converter.log", help="Путь к лог-файлу")
    return parser.parse_args()

def load_reference_genomes(ref_dir):
    references = {}
    chromosomes = [str(i) for i in range(1, 25)]
    for chrom in chromosomes:
        chrom_file = os.path.join(ref_dir, f"chr{chrom}.fa")
        if os.path.exists(chrom_file):
            try:
                references[chrom] = pysam.FastaFile(chrom_file)
            except Exception as e:
                logging.error(f"Ошибка открытия {chrom_file}: {e}")
        else:
            logging.warning(f"Файл {chrom_file} не найден")
    return references

def get_ref_base(refs, chrom, pos):
    chrom = str(chrom)
    if chrom not in refs:
        logging.warning(f"Хромосома {chrom} отсутствует в загруженных референсах")
        return None
    try:
        base = refs[chrom].fetch(f"chr{chrom}", pos - 1, pos).upper()
        return base
    except Exception as e:
        logging.error(f"Ошибка чтения {chrom}:{pos} — {e}")
        return None

def process_file(input_path, output_path, references):
    try:
        with open(input_path, "r", newline=None) as infile, open(output_path, "w") as outfile:
            header = infile.readline().strip().split("\t")
            expected = ["#CHROM", "POS", "ID", "allele1", "allele2"]
            if header != expected:
                logging.error(f"Неверный заголовок: ожидается {expected}, получено {header}")
                sys.exit(1)
            outfile.write("\t".join(["#CHROM", "POS", "ID", "REF", "ALT"]) + "\n")

            for lineno, line in enumerate(infile, start=2):
                parts = line.strip().split("\t")
                if len(parts) != 5:
                    logging.warning(f"Строка {lineno}: ожидается 5 колонок, получено {len(parts)}")
                    continue
                chrom_raw, pos_str, snp_id, allele1, allele2 = parts
                chrom = chrom_raw.replace("chr", "")  # удалим chr если случайно добавлен
                try:
                    pos = int(pos_str)
                except ValueError:
                    logging.warning(f"Строка {lineno}: POS не является числом: {pos_str}")
                    continue

                ref_base = get_ref_base(references, chrom, pos)
                if not ref_base:
                    logging.info(f"{chrom}:{pos} — референс не определён")
                    continue

                allele1 = allele1.upper()
                allele2 = allele2.upper()

                if allele1 == ref_base:
                    ref, alt = allele1, allele2
                elif allele2 == ref_base:
                    ref, alt = allele2, allele1
                else:
                    logging.info(f"{chrom}:{pos} — ни один аллель не совпадает с референсом ({ref_base})")
                    continue

                outfile.write("\t".join([f"chr{chrom}", str(pos), snp_id, ref, alt]) + "\n")

    except FileNotFoundError:
        logging.error(f"Файл {input_path} не найден")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Ошибка при обработке файла: {e}")
        sys.exit(1)

def main():
    args = parse_args()
    setup_logging(args.log)
    logging.info("=== Старт обработки SNP ===")
    refs = load_reference_genomes(args.ref_dir)
    if not refs:
        logging.error("Не загружено ни одного файла референса. Завершение.")
        sys.exit(1)
    process_file(args.input, args.output, refs)
    logging.info("=== Обработка завершена ===")

if __name__ == "__main__":
    main()
