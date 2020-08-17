########################################################################
#                                                                      #
# Run and test PhageBoost                                              #
#                                                                      #
# PhageBoost is available from                                         #
# https://github.com/ku-cbd/PhageBoost                                 #
# https://www.biorxiv.org/content/10.1101/2020.08.09.243022v1.full.pdf #
#                                                                      #
#                                                                      #
########################################################################



test_genomes = "genbank"
GENOMES, = glob_wildcards(os.path.join(test_genomes, '{genome}.gb.gz'))

outputdir = "phageboost_tests"


rule all:
    input:
        expand(os.path.join(outputdir, "{genome}_phageboost_tptn.tsv"), genome=GENOMES)


rule run_phageboost:
    input:
        gen = os.path.join(test_genomes, "{genome}.gb.gz")
    output:
        tsv = os.path.join(outputdir, "{genome}_phageboost.tsv")
    benchmark:
        os.path.join(outputdir, "benchmarks", "{genome}_phageboost.txt")
    conda:
        "conda_environments/phageboost.yaml"
    shell:
        """
        python3 scripts/phageboost_genbank.py -g {input.gen} -o {output.tsv} -m data/model_delta_std_hacked.pickled.silent.gz
        """

rule phageboost_to_tbl:
    input:
        tsv = os.path.join(outputdir, "{genome}_phageboost.tsv")
    output:
        os.path.join(outputdir, "{genome}_phageboost_locs.tsv")
    shell:
        """
        if [ $(stat -c %s {input}) -lt 50 ]; then
            touch {output}
        else
            grep -v probability {input.tsv} | cut -f 3,4,5 > {output}
        fi
        """

rule count_tp_tn:
    input:
        gen = os.path.join(test_genomes, "{genome}.gb.gz"),
        tbl = os.path.join(outputdir, "{genome}_phageboost_locs.tsv")
    output:
        tp = os.path.join(outputdir, "{genome}_phageboost_tptn.tsv")
    shell:
        """
        python3 scripts/compare_predictions_to_phages.py -t {input.gen} -r {input.tbl} > {output.tp}
        """
