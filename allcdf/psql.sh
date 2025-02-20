#!/bin/bash
# MERGE_MODE=1 (use merge DBs mode instead of generating data via 'gha2db')
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_MGETC=y structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql allcdf -c "create extension if not exists pgcrypto" || exit 1
if [ ! -z "$MERGE_MODE" ]
then
  GHA2DB_INPUT_DBS="spinnaker,tekton,jenkins,jenkinsx,cdevents,ortelius/azure-infra,ortelius/backstage,ortelius/cli,ortelius/dev-env-setup,ortelius/keptn-config,ortelius/keptn-ortelius-service,ortelius/la-sbom-ledger,ortelius/ms-compitem-crud,ortelius/ms-dep-pkg-cud,ortelius/ms-dep-pkg-r,ortelius/ms-postgres,ortelius/ms-scorecard,ortelius/ms-textfile-crud,ortelius/ms-validate-user,ortelius/ortelius,ortelius/ortelius-charts,ortelius/ortelius-docs,ortelius/ortelius-kubernetes,ortelius/ortelius-python-client,ortelius/ortelius-test-database,ortelius/ortelius-toc,ortelius/ortelius.io,ortelius/outreach,pyrsia,screwdrivercd,shipwright" GHA2DB_OUTPUT_DB="allcdf" merge_dbs || exit 2
else
  GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now 'spinnaker,tektoncd,tektoncd-catalog,jenkinsci,jenkins-infra,jenkins-x,jenkins-x-quickstarts,jenkins-x-apps,jenkins-x-charts,jenkins-x-buildpacks,jenkins-x-images,jenkins-x-plugins,knative/build,cdevents,ortelius,pyrsia,screwdriver-cd,shipwright-io,redhat-developer/build,redhat-developer/buildv2,redhat-developer/buildv2-operator' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 gha2db 2012-07-01 0 2014-12-31 23 'jenkinsci/jenkins,jenkins,jenkins-infra' 2>>errors.txt | tee -a run.log || exit 4
fi
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 8
GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 9
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_VARS="projects_health_partial_html" vars || exit 10
./devel/ro_user_grants.sh allcdf || exit 11
./devel/psql_user_grants.sh devstats_team allcdf || exit 12
