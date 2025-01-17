require 'rails_helper'

RSpec.describe "Admin::UsersController", type: :request do
  let(:default_params) do
    { organization_id: @organization.id }
  end
  let(:org) { FactoryBot.create(:organization, name: 'Org ABC') }
  let(:partner) { FactoryBot.create(:partner, name: 'Partner XYZ') }
  let(:user) { FactoryBot.create(:user, organization: org, name: 'User 123') }

  context "When logged in as a super admin" do
    before do
      sign_in(@super_admin)
      create(:organization)
      AddRoleService.call(user_id: user.id, resource_type: Role::PARTNER, resource_id: partner.id)
    end

    describe "GET #edit" do
      it "renders edit template and shows roles" do
        get edit_admin_user_path(user)
        expect(response).to render_template(:edit)
        expect(response.body).to include('User 123')
        expect(response.body).to include('Org ABC')
        expect(response.body).to include('Partner XYZ')
      end
    end

    describe '#add_role' do
      context 'with no errors' do
        it 'should call the service and redirect back' do
          allow(AddRoleService).to receive(:call)
          post admin_user_add_role_path(user_id: user.id,
            resource_type: Role::ORG_ADMIN,
            resource_id: org.id),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(AddRoleService).to have_received(:call).with(user_id: user.id.to_s,
            resource_type: Role::ORG_ADMIN.to_s,
            resource_id: org.id.to_s)
          expect(flash[:notice]).to eq('Role added!')
          expect(response).to redirect_to('/back/url')
        end
      end

      context 'with errors' do
        it 'should redirect back with error' do
          allow(AddRoleService).to receive(:call).and_raise('OH NOES')
          post admin_user_add_role_path(user_id: user.id,
            resource_type: Role::ORG_ADMIN,
            resource_id: org.id),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(AddRoleService).to have_received(:call).with(user_id: user.id.to_s,
            resource_type: Role::ORG_ADMIN.to_s,
            resource_id: org.id.to_s)
          expect(flash[:alert]).to eq('OH NOES')
          expect(response).to redirect_to('/back/url')
        end
      end
    end

    describe '#remove_role' do
      context 'with no errors' do
        it 'should call the service and redirect back' do
          allow(RemoveRoleService).to receive(:call)
          delete admin_user_remove_role_path(user_id: user.id,
            role_id: 123),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(RemoveRoleService).to have_received(:call).with(user_id: user.id.to_s,
            role_id: '123')
          expect(flash[:notice]).to eq('Role removed!')
          expect(response).to redirect_to('/back/url')
        end
      end

      context 'with errors' do
        it 'should redirect back with error' do
          allow(RemoveRoleService).to receive(:call).and_raise('OH NOES')
          delete admin_user_remove_role_path(user_id: user.id,
            role_id: 123),
            headers: { 'HTTP_REFERER' => '/back/url'}
          expect(RemoveRoleService).to have_received(:call).with(user_id: user.id.to_s,
            role_id: '123')
          expect(flash[:alert]).to eq('OH NOES')
          expect(response).to redirect_to('/back/url')
        end
      end
    end

    describe "GET #new" do
      it "renders new template" do
        get new_admin_user_path
        expect(response).to render_template(:new)
      end

      it "preloads organizations" do
        get new_admin_user_path
        expect(assigns(:organizations)).to eq(Organization.all.alphabetized)
      end
    end

    describe "POST #create" do
      it "returns http success" do
        post admin_users_path, params: { user: { email: 'email@email.com', organization_id: 1 } }
        expect(response).to redirect_to(admin_users_path(organization_id: 'admin'))
      end

      it "preloads organizations" do
        post admin_users_path, params: { user: { organization_id: 1 } }
        expect(assigns(:organizations)).to eq(Organization.all.alphabetized)
      end
    end
  end

  context "When logged in as an organization_admin" do
    before do
      sign_in @organization_admin
      create(:organization)
    end

    describe "GET #new" do
      it "redirects" do
        get new_admin_user_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    describe "POST #create" do
      it "redirects" do
        post admin_users_path, params: { user: { organization_id: 1 } }
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  context "When logged in as a non-admin user" do
    before do
      sign_in @user
      create(:organization)
    end

    describe "GET #new" do
      it "redirects" do
        get new_admin_user_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    describe "POST #create" do
      it "redirects" do
        post admin_users_path, params: { user: { organization_id: 1 } }
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
