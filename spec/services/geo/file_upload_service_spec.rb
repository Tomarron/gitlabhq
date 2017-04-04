require 'spec_helper'

describe Geo::FileUploadService, services: true do
  let!(:node) { create(:geo_node, :current) }

  describe '#execute' do
    context 'user avatar' do
      let(:user) { create(:user, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: user, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:avatar_transfer) { Gitlab::Geo::AvatarTransfer.new(upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(avatar_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends avatar file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].file.path).to eq(user.avatar.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'group avatar' do
      let(:group) { create(:group, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: group, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:avatar_transfer) { Gitlab::Geo::AvatarTransfer.new(upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(avatar_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends avatar file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].file.path).to eq(group.avatar.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'project avatar' do
      let(:project) { create(:empty_project, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: project, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:avatar_transfer) { Gitlab::Geo::AvatarTransfer.new(upload) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(avatar_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends avatar file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].file.path).to eq(project.avatar.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end

    context 'LFS Object' do
      let(:lfs_object) { create(:lfs_object, :with_file) }
      let(:params) { { id: lfs_object.id, type: 'lfs' } }
      let(:lfs_transfer) { Gitlab::Geo::LfsTransfer.new(lfs_object) }
      let(:transfer_request) { Gitlab::Geo::TransferRequest.new(lfs_transfer.request_data) }
      let(:req_header) { transfer_request.headers['Authorization'] }

      it 'sends LFS file' do
        service = described_class.new(params, req_header)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].file.path).to eq(lfs_object.file.path)
      end

      it 'returns nil if no authorization' do
        service = described_class.new(params, nil)

        expect(service.execute).to be_nil
      end
    end
  end
end
