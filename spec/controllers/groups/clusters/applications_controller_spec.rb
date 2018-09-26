require 'spec_helper'

describe Groups::Clusters::ApplicationsController do
  include AccessMatchersForController

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  def current_application
    Clusters::Cluster::APPLICATIONS[application]
  end

  describe 'POST create' do
    let(:cluster) { create(:cluster, :provided_by_gcp, groups: [group]) }
    let(:application) { 'helm' }
    let(:params) { { application: application, id: cluster.id } }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        group.add_maintainer(user)
        sign_in(user)
      end

      it 'schedule an application installation' do
        expect(ClusterInstallAppWorker).to receive(:perform_async).with(application, anything).once

        expect { go }.to change { current_application.count }
        expect(response).to have_http_status(:no_content)
        expect(cluster.application_helm).to be_scheduled
      end

      context 'when cluster do not exists' do
        before do
          cluster.destroy!
        end

        it 'return 404' do
          expect { go }.not_to change { current_application.count }
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when application is unknown' do
        let(:application) { 'unkwnown-app' }

        it 'return 404' do
          go

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when application is already installing' do
        before do
          create(:clusters_applications_helm, :installing, cluster: cluster)
        end

        it 'returns 400' do
          go

          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    describe 'security' do
      before do
        allow(ClusterInstallAppWorker).to receive(:perform_async)
      end

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end

    def go
      post :create, params.merge(group_id: group)
    end
  end
end