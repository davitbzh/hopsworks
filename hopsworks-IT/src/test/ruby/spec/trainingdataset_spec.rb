# This file is part of Hopsworks
# Copyright (C) 2020, Logical Clocks AB. All rights reserved
#
# Hopsworks is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Hopsworks is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.

describe "On #{ENV['OS']}" do
  after(:all) {clean_all_test_projects(spec: "trainingdataset")}

  describe "training dataset" do
    describe "internal" do
      context 'with valid project, featurestore service enabled' do
        before :all do
          with_valid_project
        end

        it "should be able to add a hopsfs training dataset to the featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          parsed_json = JSON.parse(json_result)
          expect_status(201)
          expect(parsed_json.key?("id")).to be true
          expect(parsed_json.key?("featurestoreName")).to be true
          expect(parsed_json.key?("name")).to be true
          expect(parsed_json.key?("creator")).to be true
          expect(parsed_json.key?("location")).to be true
          expect(parsed_json.key?("version")).to be true
          expect(parsed_json.key?("dataFormat")).to be true
          expect(parsed_json.key?("trainingDatasetType")).to be true
          expect(parsed_json.key?("location")).to be true
          expect(parsed_json.key?("storageConnectorId")).to be true
          expect(parsed_json.key?("storageConnectorName")).to be true
          expect(parsed_json.key?("inodeId")).to be true
          expect(parsed_json.key?("features")).to be true
          expect(parsed_json.key?("seed")).to be true
          expect(parsed_json["featurestoreName"] == project.projectname.downcase + "_featurestore").to be true
          expect(parsed_json["name"] == training_dataset_name).to be true
          expect(parsed_json["trainingDatasetType"] == "HOPSFS_TRAINING_DATASET").to be true
          expect(parsed_json["storageConnectorId"] == connector.id).to be true
          expect(parsed_json["features"].length).to be 2
          expect(parsed_json["seed"] == 1234).to be true


          # Make sure the location contains the scheme (hopsfs) and the authority
          uri = URI(parsed_json["location"])
          expect(uri.scheme).to eql("hopsfs")
          # If the port is available we can assume that the IP is as well.
          expect(uri.port).to eql(8020)
        end

        it "should not be able to add a hopsfs training dataset to the featurestore with upper case characters" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          training_dataset_name = "TEST_training_dataset"
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector, name:training_dataset_name)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270091).to be true
        end

        it "should not be able to add a hopsfs training dataset to the featurestore without specifying a data format" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector, data_format: "")
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270057).to be true
        end

        it "should not be able to add a hopsfs training dataset to the featurestore with an invalid version" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector,
                                                                              version: -1)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270058).to be true
        end

        it "should be able to add a new hopsfs training dataset without version to the featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector,
                                                                              name: "no_version_td", version: nil)
          parsed_json = JSON.parse(json_result)
          expect_status(201)
          expect(parsed_json["version"] == 1).to be true
        end

        it "should be able to add a new version of an existing hopsfs training dataset without version to the featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector,
                                                                              name: "no_version_td_add")
          parsed_json = JSON.parse(json_result)
          expect_status(201)
          # add second version
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector,
                                                                              name: "no_version_td_add", version: nil)
          parsed_json = JSON.parse(json_result)
          expect_status(201)
          # version should be incremented to 2
          expect(parsed_json["version"] == 2).to be true
        end

        it "should be able to add a hopsfs training dataset to the featurestore with splits" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          splits = [
              {
                  name: "test_split",
                  percentage: 0.8
              },
              {
                  name: "train_split",
                  percentage: 0.2
              }
          ]
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector,
                                                                              splits: splits)
          parsed_json = JSON.parse(json_result)
          expect_status(201)
          expect(parsed_json.key?("splits")).to be true
          expect(parsed_json["splits"].length).to be 2
        end

        it "should not be able to add a hopsfs training dataset to the featurestore with a non numeric split percentage" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          split = [{name: "train_split", percentage: "wrong"}]
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector, splits: split)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270099).to be true
        end

        it "should not be able to add a hopsfs training dataset to the featurestore with a illegal split name" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          split = [{name: "ILLEGALNAME!!!", percentage: 0.8}]
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector, splits: split)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270098).to be true
        end

        it "should not be able to add a hopsfs training dataset to the featurestore with splits of duplicate split
          names" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          splits = [
              {
                  name: "test_split",
                  percentage: 0.8
              },
              {
                  name: "test_split",
                  percentage: 0.2
              }
          ]
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector,
                                                                              splits: splits)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270106).to be true
        end

        it "should not be able to create a training dataset with the same name and version" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          parsed_json = JSON.parse(json_result)
          expect_status(201)

          create_hopsfs_training_dataset(project.id, featurestore_id, connector, name: training_dataset_name)
          expect_status(400)
        end

        it "should be able to add a hopsfs training dataset to the featurestore without specifying a hopsfs connector" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          json_result, _ = create_hopsfs_training_dataset(project.id, featurestore_id, nil)
          parsed_json = JSON.parse(json_result)
          expect_status(201)
          expect(parsed_json["storageConnectorName"] == "#{project['projectname']}_Training_Datasets")
        end

        it "should be able to delete a hopsfs training dataset from the featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result1, _ = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)
          training_dataset_id = parsed_json1["id"]
          delete_training_dataset_endpoint = "#{ENV['HOPSWORKS_API']}/project/" + project.id.to_s +
              "/featurestores/" + featurestore_id.to_s + "/trainingdatasets/" + training_dataset_id.to_s
          json_result2 = delete delete_training_dataset_endpoint
          expect_status(200)

          # Make sure that the directory has been removed correctly
          get_datasets_in_path(project,
                               "#{project[:projectname]}_Training_Datasets/#{parsed_json1['name']}_#{parsed_json1['version']}",
                               query: "&type=DATASET")
          expect_status(400)
        end

        it "should not be able to update the metadata of a hopsfs training dataset from the featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result1, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)
          training_dataset_id = parsed_json1["id"]
          json_result2 = update_hopsfs_training_dataset_metadata(project.id, featurestore_id, training_dataset_id, "petastorm", connector)
          parsed_json2 = JSON.parse(json_result2)
          expect_status(200)
          expect(parsed_json2.key?("id")).to be true
          expect(parsed_json2.key?("name")).to be true
          expect(parsed_json2.key?("creator")).to be true
          expect(parsed_json2.key?("location")).to be true
          expect(parsed_json2.key?("version")).to be true
          expect(parsed_json2.key?("dataFormat")).to be true
          expect(parsed_json2.key?("trainingDatasetType")).to be true
          expect(parsed_json2.key?("storageConnectorId")).to be true
          expect(parsed_json2.key?("storageConnectorName")).to be true
          expect(parsed_json2.key?("inodeId")).to be true

          # make sure the dataformat didn't change
          expect(parsed_json2["dataFormat"] == "tfrecords").to be true
        end

        it "should not be able to update the name of a training dataset" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result1, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)

          training_dataset_id = parsed_json1["id"]
          json_result2 = update_hopsfs_training_dataset_metadata(project.id, featurestore_id,
                                                                 training_dataset_id, "tfrecords", connector)
          parsed_json2 = JSON.parse(json_result2)
          expect_status(200)

          # make sure the name didn't change
          expect(parsed_json2["name"]).to eql(training_dataset_name)
        end

        it "should be able to update the description of a training dataset" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result1, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)

          training_dataset_id = parsed_json1["id"]
          json_result2 = update_hopsfs_training_dataset_metadata(project.id, featurestore_id,
                                                                 training_dataset_id, "tfrecords", connector)
          parsed_json2 = JSON.parse(json_result2)
          expect_status(200)

          expect(parsed_json2["description"]).to eql("new_testtrainingdatasetdescription")
          # make sure the name didn't change
          expect(parsed_json2["name"]).to eql(training_dataset_name)
        end

        it "should be able to update the jobs of a training dataset" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result1, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)

          # Create a fake job
          create_sparktour_job(project, "ingestion_job", "jar", nil)

          jobs = [{"jobName" => "ingestion_job"}]

          training_dataset_id = parsed_json1["id"]
          json_result2 = update_hopsfs_training_dataset_metadata(project.id, featurestore_id,
                                                                 training_dataset_id, "tfrecords", connector, jobs: jobs)
          parsed_json2 = JSON.parse(json_result2)
          expect_status(200)

          # make sure the name didn't change
          expect(parsed_json2["jobs"].count).to eql(1)
          expect(parsed_json2["jobs"][0]["jobName"]).to eql("ingestion_job")
        end

        it "should be able to get a list of training dataset versions based on the name" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          expect_status(201)

          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector, name: training_dataset_name, version: 2)
          expect_status(201)

          # Get the list
          get_training_datasets_endpoint = "#{ENV['HOPSWORKS_API']}/project/#{project.id}/featurestores/#{featurestore_id}/trainingdatasets/#{training_dataset_name}"
          get get_training_datasets_endpoint
          parsed_json = JSON.parse(response.body)
          expect_status(200)
          expect(parsed_json.size).to eq 2
        end

        it "should be able to get a training dataset based on name and version" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          expect_status(201)

          json_result, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector, name: training_dataset_name, version: 2)
          expect_status(201)

          # Get the first version
          get_training_datasets_endpoint = "#{ENV['HOPSWORKS_API']}/project/#{project.id}/featurestores/#{featurestore_id}/trainingdatasets/#{training_dataset_name}?version=1"
          get get_training_datasets_endpoint
          parsed_json = JSON.parse(response.body)
          expect_status(200)
          expect(parsed_json[0]['version']).to be 1
          expect(parsed_json[0]['name']).to eq training_dataset_name

          get_training_datasets_endpoint = "#{ENV['HOPSWORKS_API']}/project/#{project.id}/featurestores/#{featurestore_id}/trainingdatasets/#{training_dataset_name}?version=2"
          get get_training_datasets_endpoint
          expect_status(200)
          parsed_json = JSON.parse(response.body)
          expect(parsed_json[0]['version']).to be 2
          expect(parsed_json[0]['name']).to eq training_dataset_name
        end

        it "should fail to get a training dataset with a name that does not exists" do
          # Get the list
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          get_training_datasets_endpoint = "#{ENV['HOPSWORKS_API']}/project/#{project.id}/featurestores/#{featurestore_id}/trainingdatasets/doesnotexists/"
          get get_training_datasets_endpoint
          expect_status(400)
        end
      end
    end

    describe "external" do
      context 'with valid project, s3 connector, and featurestore service enabled' do
        before :all do
          with_valid_project
          with_s3_connector(@project[:id])
        end

        it "should be able to add an external training dataset to the featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          json_result, training_dataset_name = create_external_training_dataset(project.id, featurestore_id, connector_id)
          parsed_json = JSON.parse(json_result)
          expect_status(201)
          expect(parsed_json.key?("id")).to be true
          expect(parsed_json.key?("featurestoreName")).to be true
          expect(parsed_json.key?("name")).to be true
          expect(parsed_json.key?("creator")).to be true
          expect(parsed_json.key?("location")).to be true
          expect(parsed_json.key?("version")).to be true
          expect(parsed_json.key?("dataFormat")).to be true
          expect(parsed_json.key?("trainingDatasetType")).to be true
          expect(parsed_json.key?("description")).to be true
          expect(parsed_json.key?("storageConnectorId")).to be true
          expect(parsed_json.key?("storageConnectorName")).to be true
          expect(parsed_json.key?("features")).to be true
          expect(parsed_json.key?("seed")).to be true
          expect(parsed_json["featurestoreName"] == project.projectname.downcase + "_featurestore").to be true
          expect(parsed_json["name"] == training_dataset_name).to be true
          expect(parsed_json["trainingDatasetType"] == "EXTERNAL_TRAINING_DATASET").to be true
          expect(parsed_json["storageConnectorId"] == connector_id).to be true
          expect(parsed_json["features"].length).to be 2
          expect(parsed_json["seed"] == 1234).to be true
        end

        it "should not be able to add an external training dataset to the featurestore with upper case characters" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          training_dataset_name = "TEST_training_dataset"
          json_result, training_dataset_name = create_external_training_dataset(project.id, featurestore_id, connector_id,
                                                                                name:training_dataset_name)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270091).to be true
        end

        it "should not be able to add an external training dataset to the featurestore without specifying a s3 connector" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          json_result, training_dataset_name = create_external_training_dataset(project.id, featurestore_id, nil)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
        end

        it "should be able to add an external training dataset to the featurestore with splits" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          splits = [
              {
                  name: "test_split",
                  percentage: 0.8
              },
              {
                  name: "train_split",
                  percentage: 0.2
              }
          ]
          json_result, training_dataset_name = create_external_training_dataset(project.id, featurestore_id,
                                                                                connector_id, splits: splits)

          parsed_json = JSON.parse(json_result)
          expect_status(201)
          expect(parsed_json.key?("splits")).to be true
          expect(parsed_json["splits"].length).to be 2
        end

        it "should not be able to add an external training dataset to the featurestore with a non numeric split percentage" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          splits = [{name: "train_split", percentage: "wrong"}]
          json_result, training_dataset_name = create_external_training_dataset(project.id, featurestore_id,
                                                                                connector_id, splits: splits)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270099).to be true
        end

        it "should not be able to add an external training dataset to the featurestore with a illegal split name" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          splits = [{name: "ILLEGALNAME!!!", percentage: 0.8}]
          json_result, training_dataset_name = create_external_training_dataset(project.id, featurestore_id,
                                                                                connector_id, splits: splits)
          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270098).to be true
        end

        it "should not be able to add an external training dataset to the featurestore with splits of
        duplicate split names" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          splits = [
              {
                  name: "test_split",
                  percentage: 0.8
              },
              {
                  name: "test_split",
                  percentage: 0.2
              }
          ]
          json_result, training_dataset_name = create_external_training_dataset(project.id, featurestore_id,
                                                                                connector_id, splits: splits)

          parsed_json = JSON.parse(json_result)
          expect_status(400)
          expect(parsed_json.key?("errorCode")).to be true
          expect(parsed_json.key?("errorMsg")).to be true
          expect(parsed_json.key?("usrMsg")).to be true
          expect(parsed_json["errorCode"] == 270106).to be true
        end

        it "should be able to delete an external training dataset from the featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          json_result1, training_dataset_name = create_external_training_dataset(project.id, featurestore_id, connector_id)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)
          training_dataset_id = parsed_json1["id"]
          delete_training_dataset_endpoint = "#{ENV['HOPSWORKS_API']}/project/" + project.id.to_s +
              "/featurestores/" + featurestore_id.to_s + "/trainingdatasets/" + training_dataset_id.to_s
          delete delete_training_dataset_endpoint
          expect_status(200)
        end

        it "should be able to update the metadata (description) of an external training dataset from the featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          json_result1, training_dataset_name = create_external_training_dataset(project.id, featurestore_id, connector_id)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)
          training_dataset_id = parsed_json1["id"]
          json_result2 = update_external_training_dataset_metadata(project.id, featurestore_id, training_dataset_id,
                                                                   training_dataset_name, "new description",
                                                                   connector_id)
          parsed_json2 = JSON.parse(json_result2)
          expect_status(200)
          expect(parsed_json2.key?("id")).to be true
          expect(parsed_json2.key?("featurestoreName")).to be true
          expect(parsed_json2.key?("name")).to be true
          expect(parsed_json2.key?("creator")).to be true
          expect(parsed_json2.key?("location")).to be true
          expect(parsed_json2.key?("version")).to be true
          expect(parsed_json2.key?("dataFormat")).to be true
          expect(parsed_json2.key?("trainingDatasetType")).to be true
          expect(parsed_json2.key?("description")).to be true
          expect(parsed_json2.key?("storageConnectorId")).to be true
          expect(parsed_json2.key?("storageConnectorName")).to be true
          expect(parsed_json2["featurestoreName"] == project.projectname.downcase + "_featurestore").to be true
          expect(parsed_json2["description"] == "new description").to be true
          expect(parsed_json2["trainingDatasetType"] == "EXTERNAL_TRAINING_DATASET").to be true
        end

        it "should not be able do change the storage connector" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          json_result1, training_dataset_name = create_external_training_dataset(project.id, featurestore_id, connector_id)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)

          training_dataset_id = parsed_json1["id"]
          json_new_connector, _ = create_s3_connector_without_encryption(project.id, featurestore_id)
          new_connector = JSON.parse(json_new_connector)

          json_result2 = update_external_training_dataset_metadata(project.id, featurestore_id,
                                                                   training_dataset_id, training_dataset_name, "desc",
                                                                   new_connector['id'])
          parsed_json2 = JSON.parse(json_result2)
          expect_status(200)

          # make sure the name didn't change
          expect(parsed_json2["storageConnectorId"]).to be connector_id
        end

        it "should store and return the correct path within the bucket" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector_id = get_s3_connector_id
          json_result1, training_dataset_name = create_external_training_dataset(project.id, featurestore_id,
                                                                                 connector_id,
                                                                                 location: "/inner/location")
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)
          expect(parsed_json1['location']).to eql("s3://testbucket/inner/location/#{training_dataset_name}_1")
        end
      end
    end

    describe "list" do
      context 'with valid project, featurestore service enabled' do
        before :all do
          with_valid_project
        end

        it "should be able to list all training datasets of the project's featurestore" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          get_training_datasets_endpoint = "#{ENV['HOPSWORKS_API']}/project/" + project.id.to_s + "/featurestores/" + featurestore_id.to_s + "/trainingdatasets"
          json_result1 = get get_training_datasets_endpoint
          parsed_json1 = JSON.parse(response.body)
          expect_status(200)
          expect(parsed_json1.length == 0).to be true
          json_result2, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          expect_status(201)
          json_result3 = get get_training_datasets_endpoint
          parsed_json2 = JSON.parse(json_result3)
          expect_status(200)
          expect(parsed_json2.length == 1).to be true
          expect(parsed_json2[0].key?("id")).to be true
          expect(parsed_json2[0].key?("featurestoreName")).to be true
          expect(parsed_json2[0].key?("name")).to be true
          expect(parsed_json2[0]["featurestoreName"] == project.projectname.downcase + "_featurestore").to be true
          expect(parsed_json2[0]["name"] == training_dataset_name).to be true
        end

        it "should be able to get a training dataset with a particular id" do
          project = get_project
          featurestore_id = get_featurestore_id(project.id)
          connector = get_hopsfs_training_datasets_connector(@project[:projectname])
          json_result1, training_dataset_name = create_hopsfs_training_dataset(project.id, featurestore_id, connector)
          expect_status(201)
          parsed_json1 = JSON.parse(json_result1)
          expect_status(201)
          training_dataset_id = parsed_json1["id"]
          get_training_dataset_endpoint = "#{ENV['HOPSWORKS_API']}/project/" + project.id.to_s + "/featurestores/" + featurestore_id.to_s + "/trainingdatasets/" + training_dataset_id.to_s
          json_result2 = get get_training_dataset_endpoint
          parsed_json2 = JSON.parse(json_result2)
          expect_status(200)
          expect(parsed_json2.key?("id")).to be true
          expect(parsed_json2.key?("featurestoreName")).to be true
          expect(parsed_json2.key?("featurestoreId")).to be true
          expect(parsed_json2.key?("name")).to be true
          expect(parsed_json2["featurestoreId"] == featurestore_id).to be true
          expect(parsed_json2["featurestoreName"] == project.projectname.downcase + "_featurestore").to be true
          expect(parsed_json2["name"] == training_dataset_name).to be true
          expect(parsed_json2["id"] == training_dataset_id).to be true
        end
      end
    end
  end
end
