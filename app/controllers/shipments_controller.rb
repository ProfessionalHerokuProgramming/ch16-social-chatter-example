require 'httparty'

class ShipmentsController < ApplicationController
    include Databasedotcom::OAuth2::Helpers
    include HTTParty

    before_filter :init

    def init
        @authenticated = authenticated?
        
        if authenticated?
            @me = me

            # Set up URL and headers for REST calls
            @root_url = client.instance_url + "/services/data/v" +
                client.version
            @options = { 
                :headers => { 
                    'Authorization' => "OAuth #{client.oauth_token}",
                    'Content-Type' => "application/json",
                    'X-PrettyPrint' => "1"
                }
            }
        end
    end

    def logout
        client.logout if authenticated?
    end

    def post
        # Create JSON for REST request
        options = @options
        options.merge!( 
            :body => { 
                :body => { 
                    :messageSegments => [
                        {
                            :type => "Text",
                            :text => params[:content]
                        }
                    ]
                }
            }.to_json
        )

        # Do REST request
        response = HTTParty.post(@root_url + "/chatter/feeds/record/" + 
            params[:parent_id] + "/feed-items", options)
    end

    # GET /shipments
    # GET /shipments.json
    def index
    
        @shipments = Shipment.all
        
        respond_to do |format|
            format.html # index.html.erb
            format.json { render json: @shipments }
        end
    end

    # GET /shipments/1
    # GET /shipments/1.json
    def show
        # Get shipment from Postgres DB
        @shipment = Shipment.find(params[:id])
    
        # Get shadow object from database.com
        @shadow_obj = client.query("SELECT Id, Name FROM " +             
            "ShipmentChatter__c WHERE Name = \'" << params[:id] << "\'")
        @id = @shadow_obj[0].Id
    
        # Get Chatter feed for shadow object
        @feed = client.query("SELECT Body, InsertedById FROM " +
            "FeedItem WHERE ParentId = \'" + @id +  "\' ORDER BY CreatedDate")
    
        # Get User list for identifying Chatter post user
        @user_list = Hash.new()
        raw_user_list = client.query("SELECT Id, Name FROM User")
        raw_user_list.each do |user|
            @user_list[user.Id] = user.Name
        end
    
        respond_to do |format|
          format.html # show.html.erb
          format.json { render json: @shipment }
        end
    end

    # GET /shipments/new
    # GET /shipments/new.json
    def new
        @shipment = Shipment.new
        
        respond_to do |format|
            format.html # new.html.erb
            format.json { render json: @shipment }
        end
    end

    # GET /shipments/1/edit
    def edit
        @shipment = Shipment.find(params[:id])
    end

    # POST /shipments
    # POST /shipments.json
    def create
        # Save shipment in Postgres DB
        @shipment = Shipment.new(params[:shipment])

        respond_to do |format|
            if @shipment.save

                # Create JSON for REST request
                options = @options
                options.merge!( 
                    :body => { 
                        :Name => @shipment.id
                    }.to_json
                )
                
                # Do REST request
                response = HTTParty.post(@root_url + 
                    "/sobjects/ShipmentChatter__c", options)
                
                format.html { redirect_to @shipment, notice: 
                    'Shipment was successfully created.' }
                format.json { render json: @shipment, status: :created, 
                    location: @shipment }
            else
                format.html { render action: "new" }
                format.json { render json: @shipment.errors, 
                    status: :unprocessable_entity }
            end
        end
    end

    # PUT /shipments/1
    # PUT /shipments/1.json
    def update
        @shipment = Shipment.find(params[:id])
        
        respond_to do |format|
            if @shipment.update_attributes(params[:shipment])
                format.html { redirect_to @shipment, 
                    notice: 'Shipment was successfully updated.' }
                format.json { head :no_content }
            else
                format.html { render action: "edit" }
                format.json { render json: @shipment.errors, 
                    status: :unprocessable_entity }
            end
        end
    end

    # DELETE /shipments/1
    # DELETE /shipments/1.json
    def destroy
        @shipment = Shipment.find(params[:id])
        @shipment.destroy
        
        respond_to do |format|
            format.html { redirect_to shipments_url }
            format.json { head :no_content }
        end
    end
end
