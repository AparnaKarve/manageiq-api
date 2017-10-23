RSpec.describe 'CustomButtons API' do
  let(:object_def) { FactoryGirl.create(:generic_object_definition, :name => 'foo') }
  let(:cb) { FactoryGirl.create(:custom_button, :name => 'custom_button', :applies_to_class => 'GenericObjectDefinition', :applies_to_id => object_def.id) }
  let(:cb2) { FactoryGirl.create(:custom_button, :name => 'custom_button') }

  describe 'GET /api/custom_buttons' do
    it 'does not list custom buttons without an appropriate role' do
      api_basic_authorize

      get(api_custom_buttons_url)

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists all custom buttons with an appropriate role' do
      api_basic_authorize collection_action_identifier(:custom_buttons, :read, :get)
      cb_href = api_custom_button_url(nil, cb)

      get(api_custom_buttons_url)

      expected = {
          'count'     => 1,
          'subcount'  => 1,
          'name'      => 'custom_buttons',
          'resources' => [
            hash_including('href' => cb_href)
          ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'GET /api/custom_buttons/:id' do
    it 'does not let you query custom buttons without an appropriate role' do
      api_basic_authorize

      get(api_custom_button_url(nil, cb))

      expect(response).to have_http_status(:forbidden)
    end

    it 'can query a custom button by its id' do
      api_basic_authorize action_identifier(:custom_buttons, :read, :resource_actions, :get)

      get(api_custom_button_url(nil, cb))

      expected = {
          'id'   => cb.id.to_s,
          'name' => "custom_button"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/custom_buttons' do
    it 'can create a new custom button' do
      api_basic_authorize collection_action_identifier(:custom_buttons, :create)

      cb_rec = {
        'name'             => 'Generic Object Custom Button',
        'description'      => 'Generic Object Custom Button description',
        'applies_to_class' => 'GenericObjectDefinition',
        # 'applies_to_id'    =>  object_def.id,
        'options'          => {
            'button_icon'  => 'ff ff-view-expanded',
            'button_color' => '#4727ff',
            'display'      => true,
        },
      }
      post(api_custom_buttons_url, :params => cb_rec)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['results'].first).to include(cb_rec)
    end

    it 'can edit custom buttons by id' do
      api_basic_authorize collection_action_identifier(:custom_buttons, :edit)

      request = {
          'action'    => 'edit',
          'resources' => [
              { 'id' => cb.id.to_s, 'name' => 'updated 1' },
          ]
      }
      post(api_custom_buttons_url, :params => request)

      expected = {
          'results' => a_collection_including(
              a_hash_including('id' => cb.id.to_s, 'name' => 'updated 1'),
          )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/custom_buttons/:id' do
    it 'can update a custom buttons by id' do
      api_basic_authorize action_identifier(:custom_buttons, :edit)

      request = {
          'action'      => 'edit',
          'name'        => 'Generic Object Custom Button Updated',
          'description' => 'Generic Object Custom Button description Updated',
      }
      post(api_custom_button_url(nil, cb), :params => request)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(request.except('action'))
    end

    it 'can delete a custom button by id' do
      api_basic_authorize action_identifier(:custom_buttons, :delete)

      post(api_custom_button_url(nil, cb), :params => { :action => 'delete' })

      expect(response).to have_http_status(:ok)
    end

    it 'can delete custom button in bulk by id' do
      api_basic_authorize collection_action_identifier(:custom_buttons, :delete)

      request = {
          'action'    => 'delete',
          'resources' => [
              { 'id' => cb.id.to_s}
          ]
      }
      post(api_custom_buttons_url, :params => request)

      expected = {
          'results' => a_collection_including(
              a_hash_including('success' => true, 'message' => "custom_buttons id: #{cb.id} deleting")
          )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'DELETE /api/custom_buttons/:id' do
    it 'can delete a custom button by id' do
      api_basic_authorize action_identifier(:custom_buttons, :delete, :resource_actions, :delete)

      delete(api_custom_button_url(nil, cb))

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PUT /api/custom_buttons/:id' do
    it 'can edit a custom button' do
      api_basic_authorize action_identifier(:custom_buttons, :edit)

      request = {
          'name'        => 'Generic Object Custom Button Updated',
          'description' => 'Generic Object Custom Button Description Updated',
      }
      put(api_custom_button_url(nil, cb), :params => request)

      expected = {
          'name'        => 'Generic Object Custom Button Updated',
          'description' => 'Generic Object Custom Button Description Updated',
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PATCH /api/custom_buttons/:id' do
    it 'can edit a custom button' do
      api_basic_authorize action_identifier(:custom_buttons, :edit)

      request = [
          {
              'action' => 'edit',
              'path'   => 'name',
              'value'  => 'Generic Object Custom Button Updated',
          },
          {
              'action' => 'edit',
              'path'   => 'description',
              'value'  => 'Generic Object Custom Button Description Updated',
          }
      ]
      patch(api_custom_button_url(nil, cb), :params => request)

      expected = {
          'name'        => 'Generic Object Custom Button Updated',
          'description' => 'Generic Object Custom Button Description Updated',
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'OPTIONS /api/custom_buttons' do
    it 'returns allowed association types and data types' do
      options(api_custom_buttons_url)
      # user = FactoryGirl.create(:user_with_group, :userid => "admin")
      @user = FactoryGirl.create(:user_with_group, 'name' => 'Fred')
      model_data_dir = Rails.root.join("spec/models/miq_ae_class/data")
      EvmSpecHelper.import_yaml_model(File.join(model_data_dir, 'domain1'), "DOMAIN1")
      EvmSpecHelper.import_yaml_model(File.join(model_data_dir, 'domain2'), "DOMAIN2")
      EvmSpecHelper.import_yaml_model(File.join(model_data_dir, 'domain3'), "DOMAIN3")
      # set_priority('domain1', 10)
      # set_priority('domain2', 20)
      # set_priority('domain3', 50)
      @inst4_list =  %w(/DOMAIN3/SYSTEM/PROCESS/inst4  /DOMAIN1/SYSTEM/PROCESS/inst4)
      @sorted_inst_list =  ['/DOMAIN3/SYSTEM/PROCESS/inst1', '/DOMAIN3/SYSTEM/PROCESS/inst2',
                            '/DOMAIN3/SYSTEM/PROCESS/inst32', '/DOMAIN3/SYSTEM/PROCESS/inst4',
                            '/DOMAIN2/SYSTEM/PROCESS/inst31', '/DOMAIN2/SYSTEM/PROCESS/inst41',
                            '/DOMAIN1/SYSTEM/PROCESS/inst3']

      expected_data = {'custom_button_types'               => CustomButton::TYPES,
                       'service_dialogs'                   => Dialog.all.pluck(:id, :label).sort,
                       'distinct_instances_across_domains' => MiqAeClass.find_distinct_instances_across_domains(User.current_user, "SYSTEM/PROCESS").pluck(:name).sort,
                       'user_roles'                        => MiqUserRole.all.pluck(:name).sort}

      expect_options_results(:custom_buttons, expected_data)
    end
  end
end
