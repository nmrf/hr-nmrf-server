require 'rails_helper'
require 'json'

RSpec.describe UserRolesController, type: :controller do
  describe 'Get index' do
    subject { get :index, format: :json }

    context 'when not signed in' do
      it { expect(subject).to be_forbidden }
    end

    context 'when signed in' do
      let(:guest) { FactoryGirl.create(:user) }
      let(:manager_role) { FactoryGirl.create(:role, :manager) }
      let(:manager) { FactoryGirl.create(:user, roles: [manager_role]) }
      let(:manager2) { FactoryGirl.create(:user, roles: [manager_role]) }
      let(:contributor_role) { FactoryGirl.create(:role, :contributor) }
      let(:contributor) { FactoryGirl.create(:user, roles: [contributor_role]) }
      let(:contributor2) { FactoryGirl.create(:user, roles: [contributor_role]) }
      let(:admin_role) { FactoryGirl.create(:role, :admin) }
      let(:admin) { FactoryGirl.create(:user, roles: [admin_role]) }
      let(:admin2) { FactoryGirl.create(:user, roles: [admin_role]) }

      it 'does not show anything to guest user' do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it 'shows all contributors for contributors' do
        contributor2
        manager
        admin
        sign_in contributor
        json = JSON.parse(subject.body)
        expect(json['data'].length).to eq(2)
        returned_roles = json['data'].map {|user_role| user_role['attributes']['role_id']}.uniq
        permitted_roles = [contributor.roles.first.id]
        expect(permitted_roles - returned_roles).to be_empty
      end

      it 'shows all managers and contributors for managers' do
        contributor
        contributor2
        manager2
        sign_in manager
        json = JSON.parse(subject.body)
        expect(json['data'].length).to eq(4)
        returned_roles = json['data'].map {|user_role| user_role['attributes']['role_id']}.uniq
        permitted_roles = [contributor.roles.first.id, manager.roles.first.id]
        expect(permitted_roles - returned_roles).to be_empty
      end

      it 'shows all user roles for admin' do
        contributor
        contributor2
        manager
        manager2
        admin2
        sign_in admin
        json = JSON.parse(subject.body)
        expect(json['data'].length).to eq(6)
        returned_roles = json['data'].map {|user_role| user_role['attributes']['role_id']}.uniq
        permitted_roles = [contributor.roles.first.id, manager.roles.first.id]
        expect(permitted_roles - returned_roles).to be_empty
      end

    end
  end

  describe 'Get show' do
    let(:user_role) { FactoryGirl.create(:user_role) }
    subject { get :show, params: { id: user_role }, format: :json }

    context 'when not signed in' do
      it 'does not show the user_role' do
        expect(subject).to be_not_found
      end
    end

    context 'when signed in' do
      let(:guest) { FactoryGirl.create(:user) }
      let(:manager) { FactoryGirl.create(:user, :manager) }
      let(:contributor) { FactoryGirl.create(:user, :contributor) }
      let(:admin) { FactoryGirl.create(:user, :admin) }

      subject { get :show, params: { id: contributor.user_roles.first.id }, format: :json }

      let(:guest) { FactoryGirl.create(:user) }
      let(:manager) { FactoryGirl.create(:user, :manager) }
      let(:contributor) { FactoryGirl.create(:user, :contributor) }
      let(:admin) { FactoryGirl.create(:user, :admin) }

      it 'shows no user_role for guest' do
        sign_in guest
        expect(subject).to be_not_found
      end
      it 'shows user_role for contributor' do
        sign_in contributor
        json = JSON.parse(subject.body)
        expect(json['data']['id'].to_i).to eq(contributor.user_roles.first.id)
      end
      it 'shows user_role for manager' do
        sign_in manager
        subject_manager = get :show, params: { id: manager.user_roles.first.id }, format: :json
        json = JSON.parse(subject_manager.body)
        expect(json['data']['id'].to_i).to eq(manager.user_roles.first.id)
      end
      it 'shows user_role for admin' do
        sign_in admin
        subject_manager = get :show, params: { id: admin.user_roles.first.id }, format: :json
        json = JSON.parse(subject_manager.body)
        expect(json['data']['id'].to_i).to eq(admin.user_roles.first.id)
      end
    end
  end

  describe 'Post create' do
    context 'when not signed in' do
      it 'not allow creating a user_role' do
        post :create, format: :json, params: { user_role: { user_id: 1, role_id: 1 } }
        expect(response).to be_unauthorized
      end
    end

    context 'when signed in' do
      let(:guest) { FactoryGirl.create(:user) }
      let(:manager_role) { FactoryGirl.create(:role, :manager) }
      let(:manager) { FactoryGirl.create(:user, roles: [manager_role]) }
      let(:contributor_role) { FactoryGirl.create(:role, :contributor) }
      let(:contributor) { FactoryGirl.create(:user, roles: [contributor_role]) }
      let(:admin_role) { FactoryGirl.create(:role, :admin) }
      let(:admin) { FactoryGirl.create(:user, roles: [admin_role]) }

      subject do
        post :create,
             format: :json,
             params: {
               user_role: {
                 user_id: guest.id,
                 role_id: contributor_role.id
               }
             }
      end

      it 'will not allow a guest to create a user_role' do
        sign_in guest
        expect(subject).to be_forbidden
      end

      it 'will allow a contributor to create a contributor user_role' do
        sign_in contributor
        subject = post :create,
                       format: :json,
                       params: {
                         user_role: {
                           user_id: guest.id,
                           role_id: contributor_role.id
                         }
                       }
        expect(subject).to be_created
      end

      it 'will not allow a contributor to create a manager or admin user_role' do
        sign_in contributor
        subject = post :create,
                       format: :json,
                       params: {
                         user_role: {
                           user_id: guest.id,
                           role_id: manager_role.id
                         }
                       }
        expect(subject).to be_forbidden
        subject = post :create,
                       format: :json,
                       params: {
                         user_role: {
                           user_id: guest.id,
                           role_id: admin_role.id
                         }
                       }
        expect(subject).to be_forbidden
      end

      it 'will allow a manager to create a manger or contributor user_role' do
        sign_in manager
        post :create,
             format: :json,
             params: {
               user_role: {
                 user_id: contributor.id,
                 role_id: manager_role.id
               }
             }
        expect(subject).to be_created
        post :create,
             format: :json,
             params: {
               user_role: {
                 user_id: manager.id,
                 role_id: contributor_role.id
               }
             }
        expect(subject).to be_created
      end

      it 'will not allow a manager to create an admin user_role' do
        sign_in manager
        subject = post :create,
                       format: :json,
                       params: {
                         user_role: {
                           user_id: guest.id,
                           role_id: admin_role.id
                         }
                       }
        expect(subject).to be_forbidden
      end

      it 'will return an error if params are incorrect' do
        sign_in admin
        post :create, format: :json, params: { user_role: { description: 'desc only', taxonomy_id: 999 } }
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'Delete destroy' do
    let(:guest) { FactoryGirl.create(:user) }
    let(:manager_role) { FactoryGirl.create(:role, :manager) }
    let(:manager) { FactoryGirl.create(:user, roles: [manager_role]) }
    let(:contributor_role) { FactoryGirl.create(:role, :contributor) }
    let(:contributor_role2) { FactoryGirl.create(:role, :contributor) }
    let(:contributor) { FactoryGirl.create(:user, roles: [contributor_role]) }
    let(:contributor2) { FactoryGirl.create(:user, roles: [contributor_role2]) }
    let(:admin_role) { FactoryGirl.create(:role, :admin) }
    let(:admin) { FactoryGirl.create(:user, roles: [admin_role]) }

    subject { delete :destroy, format: :json, params: { id: contributor.user_roles.first } }

    context 'when not signed in' do
      it 'not allow deleting a user_role' do
        expect(subject).to be_unauthorized
      end
    end

    context 'when user signed in' do
      it 'will not allow a guest to delete a user_role' do
        sign_in guest
        expect(subject).to be_not_found
      end

      it 'will not allow a contributor to delete a user_role' do
        sign_in contributor
        expect(subject).to be_forbidden
      end

      it 'will allow a manager to delete a contributor user_role' do
        sign_in manager
        subject = delete :destroy, format: :json, params: { id: contributor.user_roles.first }
        expect(subject).to be_no_content
      end

      it 'will allow an admin to delete a manager and contributor user_role' do
        sign_in admin
        subject = delete :destroy, format: :json, params: { id: manager.user_roles.first }
        expect(subject).to be_no_content
        subject = delete :destroy, format: :json, params: { id: contributor2.user_roles.first }
        expect(subject).to be_no_content
      end
    end
  end
end
