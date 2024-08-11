# name: discourse-user-api-key
# about: 允许用户生成和管理自己的 API 密钥
# version: 0.1
# authors: Your Name
# url: https://github.com/your-username/discourse-user-api-key

enabled_site_setting :user_api_key_enabled

PLUGIN_NAME ||= "discourse-user-api-key".freeze

after_initialize do
  module ::DiscourseUserApiKey
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseUserApiKey
    end
  end

  class DiscourseUserApiKey::UserApiKeyController < ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_logged_in

    def index
      render_serialized(current_user.api_keys, ApiKeySerializer)
    end

    def create
      params.require(:scopes)
      
      user = current_user
      allowed_scopes = %w[read write push]
      scopes = params[:scopes].select { |scope| allowed_scopes.include?(scope) }

      if scopes.empty?
        return render json: { error: "没有提供有效的作用域" }, status: 400
      end

      api_key = ApiKey.create!(
        user: user,
        created_by: user,
        scopes: scopes
      )

      render json: { key: api_key.key, scopes: api_key.scopes }
    end

    def destroy
      api_key = current_user.api_keys.find_by(id: params[:id])
      raise Discourse::InvalidParameters.new(:id) unless api_key

      api_key.destroy!
      render json: success_json
    end
  end

  Discourse::Application.routes.append do
    mount ::DiscourseUserApiKey::Engine, at: "/user-api-key"
  end

  add_to_serializer(:current_user, :can_create_api_key) { true }

  DiscourseUserApiKey::Engine.routes.draw do
    get "/" => "user_api_key#index"
    post "/create" => "user_api_key#create"
    delete "/:id" => "user_api_key#destroy"
  end
end

register_asset "stylesheets/user-api-key.scss"
