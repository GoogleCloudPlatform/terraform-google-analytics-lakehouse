# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).
This changelog is generated automatically based on [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [0.5.0](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/compare/v0.4.0...v0.5.0) (2026-02-24)


### ⚠ BREAKING CHANGES

* **TPG>=6.11:** set delete protection to false for workflow resources ([#208](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/208))
* **deps:** Update Terraform terraform-google-modules/project-factory/google to v17 ([#193](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/193))

### Features

* Add support for make it mine and deploy via cloudbuild trigger ([#140](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/140)) ([a465da6](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/a465da64409b07f5ec6f8e5f7e3a2e05a37d02fa))
* Adding data quality rule to workflow and removing BQML ([#153](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/153)) ([c8170e4](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/c8170e4cef21040f72b1d0fe242280f9c4540683))
* **deps:** Update Terraform Google Provider to v6 (major) ([#186](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/186)) ([60c5538](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/60c55389f74227813bf16dedd2c18a2b46c0f45d))
* moving iceberg table creation to a stored procedure ([#124](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/124)) ([bf7ea70](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/bf7ea705f018ec3796d9d6886f803b88eda4963c))
* removing project-setup workflow ([#158](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/158)) ([4ecceda](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/4eccedad2f4707e64cb259dafefe597bc4da7c6e))
* Set Terraform required_version to &gt;= 1.5 ([#187](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/187)) ([6b20105](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/6b201051a22eb31a90cd99325530491fda1eddcc))
* Spark langchain notebook ([#152](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/152)) ([ef87e53](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/ef87e53ae4e256959c55bf79030fa1ac52a50fca))
* staging bigtable.py and updating severless spark session runtime version ([#146](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/146)) ([8a41d12](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/8a41d12098da9af86023a66d0f6c0a58f79f66cf))
* updating architecture diagrams ([#151](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/151)) ([41cea9b](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/41cea9bc43e72fb8879ca2ce36f1d2249f757247))


### Bug Fixes

* delete dataproc session with its template ([#116](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/116)) ([54bda2b](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/54bda2b8ff5612419886fcf7167b3e9874421154))
* **deps:** Update cft/developer-tools Docker tag to v1.19 ([#119](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/119)) ([732bd76](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/732bd7606612448eabf7919683de59b5838406a8))
* **deps:** Update Terraform GoogleCloudPlatform/analytics-lakehouse/google to ~&gt; 0.4 ([#121](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/121)) ([8d8520a](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/8d8520ab3b77284d25e0ca93c79dc90435d6c3f4))
* **deps:** Update Terraform terraform-google-modules/project-factory/google to v14.5.0 ([#135](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/135)) ([b8cb837](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/b8cb837937011319c4cd82b823e3e89d03ccde57))
* **deps:** Update Terraform terraform-google-modules/project-factory/google to v15.0.1 ([#165](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/165)) ([0938928](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/0938928e224b75854e9204e8f965770b7b7bee15))
* **deps:** Update Terraform terraform-google-modules/project-factory/google to v17 ([#193](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/193)) ([824b0f8](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/824b0f8ef32ec7a3ba0152ee00d3a6a3ec501319))
* increasing project id length and updating workbench config ([#167](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/167)) ([2171f9e](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/2171f9eb41e4978db416327be04f8110be1f4d1a))
* **TPG>=6.11:** set delete protection to false for workflow resources ([#208](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/208)) ([d9fa104](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/d9fa104ee5e815e13d2f8f1f3041fdf8aa82eefc))
* update to gemini 1.5 and include langchain notebook in workbench ([#183](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/183)) ([8874930](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/887493028800ea0fd666870468b3a2d2b54bbded))
* update workbench.tf to deploy in 'b' zones ([#168](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/168)) ([2ef9f32](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/2ef9f3256c120333f002340e211c93e02e8b395c))
* update workbench.tf to use cheaper disks ([#175](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/175)) ([3ef81d4](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/3ef81d48b376a6eb730a67d31e1665e2f82bb43c))

## [0.4.0](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/compare/v0.3.0...v0.4.0) (2024-01-23)


### Features

* add bucket for PHS created in Spark Serverless Interactive Tutorial ([e087195](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/e08719526836af1e4197ef55005b3291920b7909))
* adding sparkml notebook ([#99](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/99)) ([4b2169a](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/4b2169a11be058d495884a4ee455f49ef109b754))
* adding unit tests, removing unused arg from README ([#93](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/93)) ([bb9257b](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/bb9257b975d7b9635cb249f1a3867c5c0a14369b))
* create a bucket for dataplex ([#76](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/76)) ([ccadcc0](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/ccadcc0667d1b3e81f7f093c2a0acc83e567120a))
* **deps:** Update Terraform Google Provider to v5 (major) ([#79](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/79)) ([40ab09d](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/40ab09d2006f6052740afffc5df7cdaf06352c16))


### Bug Fixes

* add service account to phs cluster ([#82](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/82)) ([04a9fae](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/04a9fae8e4f1bb9cbe1a420bb9c89c79d1849ddb))
* add unique hash to the service account name ([#71](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/71)) ([c16912d](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/c16912d7c3d182671dceac4067ba196aa814948a))
* change data file paths to point to root directory ([#60](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/60)) ([4621da0](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/4621da033d56f88bb0c03948b1c2e0c5108c297d))
* **deps:** update module github.com/googlecloudplatform/cloud-foundation-toolkit/infra/blueprint-test to v0.8.0 ([#63](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/63)) ([54075a5](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/54075a59ef58fe8a156cac8f36f295ee149125a2))
* **deps:** update terraform google-beta to v4.74.0 ([#57](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/57)) ([f3848c3](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/f3848c3a71518930b94c582406d3100a0e29bcde))
* **deps:** update terraform google-beta to v4.75.0 ([#58](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/58)) ([10a452e](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/10a452e4f0e612f4ce63deb7559fc4c45bed3be0))
* **deps:** Update Terraform google-beta to v4.81.0 ([#66](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/66)) ([825fd7d](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/825fd7d163e361711c7a23c14b68b65125def50a))
* **deps:** Update Terraform google-beta to v4.82.0 ([#70](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/70)) ([cc8373f](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/cc8373fdda84690982c6c928480d67dfacb3d979))
* **deps:** Update Terraform google-beta to v4.83.0 ([#73](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/73)) ([a2cabdb](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/a2cabdb10ec92242f8d17c72f8734a47937fa7e6))
* **deps:** Update Terraform google-beta to v4.84.0 ([#74](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/74)) ([c70d9af](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/c70d9af5958fd6a6a792f1ebeee542b2f21ddb1b))
* **deps:** Update Terraform terraform-google-modules/project-factory/google to v14.3.0 ([#65](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/65)) ([a59521a](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/a59521a0f7017cee43f166677ab50546245504e2))
* **deps:** Update Terraform terraform-google-modules/project-factory/google to v14.4.0 ([#87](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/87)) ([8ca39d1](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/8ca39d18d09f6c0e5e08faa9ee5392b857d7fd96))
* remove compute instance check from integration test teardown ([#110](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/110)) ([e07095d](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/e07095df965d032a8d64f83fa5511f442cc9c433))
* rolling back PHS creation in deployment ([#105](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/105)) ([f5acf8e](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/f5acf8e9289422c549ea0243f0db5f8d3972399b))
* set staging and temp bucket for phs cluster ([#88](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/88)) ([c7ff112](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/c7ff1121a5a38645531c3eb44201c08bb6407713))
* Update Terraform versioning, improve dependency tree, remove unused table, add Managed Tables to Dataplex Assets ([#72](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/72)) ([9283feb](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/9283febc691cb313b97adc242dc38605dc3976d4))
* wait for Dataplex IAM to create lake ([#86](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/86)) ([9f42b95](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/9f42b95015f6bb65ee67c9b5ada2e06a8b9a3274))
* wait to create dataproc cluster until SA roles are assigned ([#91](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/91)) ([66bb99b](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/66bb99b2be3801abe86220f0a331c18b29bbe577))

## [0.3.0](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/compare/v0.2.1...v0.3.0) (2023-07-18)


### Bug Fixes

* **deps:** update terraform google-beta to v4.70.0 ([6460f59](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/6460f59c1bd6464dbb46b5561ee4ffa0109f75ff))
* **deps:** update terraform google-beta to v4.71.0 ([c64944b](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/c64944b1a7e3c73c87bb0bcb49696cc9b8693084))
* **deps:** update terraform google-beta to v4.73.1 ([47c1b4f](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/47c1b4f60367404c303c945d3b5dd46a0a378815))
* **deps:** update terraform google-beta to v4.73.2 ([f6f8cb8](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/f6f8cb836f6d2d67ba775b795778b754893bcca0))
* **deps:** update terraform terraform-google-modules/project-factory/google to v14.2.1 ([a6ca8a1](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/a6ca8a13dc0dbfc79683c5e43b43593957407064))
* upgrade dataplex tables to managed, create new zone, remove manual table creation ([52a45f2](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/52a45f2aee107dfd6fde04ce92e77cf7b61c4e5c))

## [0.2.1](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/compare/v0.2.0...v0.2.1) (2023-06-22)


### Bug Fixes

* update neos toc url ([#47](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/47)) ([629f00b](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/629f00b679faf1f29c676514f0ef7869c7b9ee8a))

## [0.2.0](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/compare/v0.1.0...v0.2.0) (2023-06-14)


### Features

* add polling logic to Spark workflow ([9ea1517](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/9ea151703ccdfb13998d1220f29885a55aeae547))
* adds metadata generation for the blueprint ([#34](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/34)) ([ef1b35c](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/ef1b35cf28d897cae3beff4dd4200617be902d20))


### Bug Fixes

* **deps:** update terraform google-beta to v4.69.1 ([28a034d](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/28a034d2115a0982ed3b5df02e7f91be696e8e33))
* **deps:** update terraform googles to &lt;= 4.69.0, != 4.65.0, != 4.65.1 ([9a9852e](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/9a9852e7084ae0d3e0699437ea8ec78817f33104))
* **deps:** update terraform terraform-google-modules/project-factory/google to v14 ([e5e5d00](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/e5e5d00774ee5f7881b799fbb4ad435094b3087c))
* refactor references from 'assets' directory to 'src' ([acf7efb](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/acf7efba619230102e7691778ab69e47facc27aa))
* Update int.cloudbuild.yaml to use LR billing ([#43](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/43)) ([1d0ddc7](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/1d0ddc78ec473c7ca2c0863a9abdf1da2edc15f7))

## 0.1.0 (2023-05-17)


### Features

* output.tf additions ([#14](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/14)) ([07d4ea4](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/07d4ea4afd488c5df6899529fb60556a93aaaca7))


### Bug Fixes

* Biglake cleanup ([#10](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/10)) ([98646d8](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/98646d8f305554749f5afd7ab46e790f97d527fd))
* formatting and linting ([#12](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/12)) ([5e55357](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/5e553573532115bd7888600dc0c1565f79ef5b53))
* Lakehouse cleanup ([#9](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/9)) ([c474b66](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/c474b665018babe96ab897a1a338b703ac0a3b95))
* move RAP to Neos ([#24](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/24)) ([4a2aeb6](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/4a2aeb60a32f4bc79d08f008ad69bf2bc03a3792))
* pin google provider version to before 4.65 or not equal to 4.65 ([0510153](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/0510153a1849ff5f134a28cb7569f2970c142e93))
* pin google provider version to v4.64.0 ([32a83ba](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/32a83bac28f6c50de009d15333cc3ac61fc5be0a))
* update colab link ([#16](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/16)) ([20ef826](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/20ef8266bd0c70f35625008c3806a33099ded396))
* update neos, remove solution guide output ([7357552](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/735755295278b6c89cc9dbbe811f109bf96d8b52))
* Workflow dependency ([#23](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/issues/23)) ([6e2b2df](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/6e2b2df7eba67ac2403da0a80c85a5ae99e067e9))
* workflows and remove hardcoding ([675b35c](https://github.com/GoogleCloudPlatform/terraform-google-analytics-lakehouse/commit/675b35ce15db043204dd4bcfaa73faffe2933164))

## [0.1.0](https://github.com/terraform-google-modules/terraform-google-/releases/tag/v0.1.0) - 20XX-YY-ZZ

### Features

- Initial release

[0.1.0]: https://github.com/terraform-google-modules/terraform-google-/releases/tag/v0.1.0
