# frozen_string_literal: true
class ApplicationController < ActionController::Base
  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protect_from_forgery with: :exception
  protect_from_forgery with: :null_session, if: proc { |c| c.request.format == 'application/json' }

  layout :layout_by_resource

  before_action :authenticate_user!, only: [:create, :update, :destroy]
  after_action :verify_authorized, except: [:index, :sign_in], unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index, unless: :devise_controller?

  # Allow pundit to authorize a non-logged in user
  def pundit_user
    current_user || User.new
  end

  protected

  def layout_by_resource
    devise_controller? ? 'authentication' : 'application'
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |invalid|
    render json: { error: invalid.record.errors },
           status: :unprocessable_entity
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def user_not_authorized
    if request.format == 'application/json'
      return render json: { error: 'not authorized' }, status: 403
    end

    flash[:error] = 'You are not authorized to perform this action.'
    redirect_to(root_path)
  end
end
